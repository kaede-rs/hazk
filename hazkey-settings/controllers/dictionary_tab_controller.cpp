#include "controllers/dictionary_tab_controller.h"

#include <QCheckBox>
#include <QComboBox>
#include <QFile>
#include <QFileDialog>
#include <QHeaderView>
#include <QMessageBox>
#include <QPushButton>
#include <QStandardItemModel>
#include <QStringConverter>
#include <QStyledItemDelegate>
#include <QTableView>
#include <QTextStream>
#include <algorithm>

#include "serverconnector.h"
#include "ui_mainwindow.h"
#include "user_dictionary.pb.h"

namespace hazkey::settings {

namespace {

using hazkey::dictionary::UserDictionaryEntry;

constexpr int kColumnWord = 0;
constexpr int kColumnReading = 1;
constexpr int kColumnWordClass = 2;
constexpr int kColumnPriority = 3;
constexpr int kDefaultPriority = 50;

QList<QPair<int, QString>> wordClassOptions() {
    return {
        {UserDictionaryEntry::NOUN, DictionaryTabController::tr("Noun")},
        {UserDictionaryEntry::PROPER_NOUN,
         DictionaryTabController::tr("Proper noun")},
        {UserDictionaryEntry::PERSON_NAME,
         DictionaryTabController::tr("Person name")},
        {UserDictionaryEntry::PERSON_FAMILY_NAME,
         DictionaryTabController::tr("Family name")},
        {UserDictionaryEntry::PERSON_GIVEN_NAME,
         DictionaryTabController::tr("Given name")},
        {UserDictionaryEntry::ORGANIZATION_NAME,
         DictionaryTabController::tr("Organization name")},
        {UserDictionaryEntry::PLACE_NAME,
         DictionaryTabController::tr("Place name")},
    };
}

QString wordClassLabel(int wordClass) {
    const auto options = wordClassOptions();
    for (const auto& option : options) {
        if (option.first == wordClass) {
            return option.second;
        }
    }
    return DictionaryTabController::tr("Noun");
}

class WordClassDelegate : public QStyledItemDelegate {
   public:
    explicit WordClassDelegate(QObject* parent = nullptr)
        : QStyledItemDelegate(parent) {}

    QWidget* createEditor(QWidget* parent, const QStyleOptionViewItem&,
                          const QModelIndex&) const override {
        auto* comboBox = new QComboBox(parent);
        const auto options = wordClassOptions();
        for (const auto& item : options) {
            comboBox->addItem(item.second, item.first);
        }
        return comboBox;
    }

    void setEditorData(QWidget* editor,
                       const QModelIndex& index) const override {
        auto* comboBox = qobject_cast<QComboBox*>(editor);
        if (!comboBox) return;
        const int wordClass = index.data(Qt::UserRole).toInt();
        const int idx = comboBox->findData(wordClass);
        comboBox->setCurrentIndex(idx >= 0 ? idx : 0);
    }

    void setModelData(QWidget* editor, QAbstractItemModel* model,
                      const QModelIndex& index) const override {
        auto* comboBox = qobject_cast<QComboBox*>(editor);
        if (!comboBox) return;
        const int wordClass = comboBox->currentData().toInt();
        model->setData(index, wordClassLabel(wordClass), Qt::DisplayRole);
        model->setData(index, wordClass, Qt::UserRole);
    }
};

}  // namespace

DictionaryTabController::DictionaryTabController(Ui::MainWindow* ui,
                                                  QWidget* window,
                                                  QObject* parent)
    : QObject(parent),
      ui_(ui),
      window_(window),
      model_(new QStandardItemModel(0, 4, this)) {
    model_->setHorizontalHeaderLabels({
        tr("Word"),
        tr("Reading"),
        tr("Word Class"),
        tr("Priority"),
    });
    ui_->userDictViewer->setModel(model_);
    ui_->userDictViewer->setItemDelegateForColumn(
        kColumnWordClass, new WordClassDelegate(this));
    ui_->userDictViewer->horizontalHeader()->setSectionResizeMode(
        kColumnWord, QHeaderView::Stretch);
    ui_->userDictViewer->horizontalHeader()->setSectionResizeMode(
        kColumnReading, QHeaderView::Stretch);
    ui_->userDictViewer->horizontalHeader()->setSectionResizeMode(
        kColumnWordClass, QHeaderView::ResizeToContents);
    ui_->userDictViewer->horizontalHeader()->setSectionResizeMode(
        kColumnPriority, QHeaderView::ResizeToContents);
}

void DictionaryTabController::setContext(const TabContext& context) {
    context_ = context;
}

void DictionaryTabController::connectSignals() {
    connect(ui_->userDictNewEntry, &QPushButton::clicked, this,
            &DictionaryTabController::onNewEntry);
    connect(ui_->userDictDeleteEntry, &QPushButton::clicked, this,
            &DictionaryTabController::onDeleteEntry);
    connect(ui_->userDictImport, &QPushButton::clicked, this,
            &DictionaryTabController::onImport);
    connect(ui_->userDictExport, &QPushButton::clicked, this,
            &DictionaryTabController::onExport);
}

void DictionaryTabController::appendRow(const QString& word,
                                        const QString& reading,
                                        int wordClass, int priority) {
    auto* wordItem = new QStandardItem(word);
    auto* readingItem = new QStandardItem(reading);
    auto* wordClassItem = new QStandardItem(wordClassLabel(wordClass));
    wordClassItem->setData(wordClass, Qt::UserRole);
    auto* priorityItem =
        new QStandardItem(QString::number(qBound(0, priority, 100)));
    model_->appendRow({wordItem, readingItem, wordClassItem, priorityItem});
}

bool DictionaryTabController::appendRowFromTsvLine(const QString& line) {
    if (line.isEmpty() || line.startsWith('#')) return false;
    const QStringList cols = line.split('\t');
    if (cols.size() < 2) return false;

    const QString word = cols[0].trimmed();
    const QString reading = cols[1].trimmed();
    if (word.isEmpty() || reading.isEmpty()) return false;

    int wordClass = UserDictionaryEntry::NOUN;
    if (cols.size() >= 3) {
        bool ok = false;
        const int parsed = cols[2].toInt(&ok);
        if (ok) wordClass = parsed;
    }

    int priority = kDefaultPriority;
    if (cols.size() >= 4) {
        bool ok = false;
        const int parsed = cols[3].toInt(&ok);
        if (ok) priority = parsed;
    }

    appendRow(word, reading, wordClass, priority);
    return true;
}

void DictionaryTabController::loadFromConfig() {
    model_->removeRows(0, model_->rowCount());

    if (!context_.server) return;
    const auto dict = context_.server->getUserDictionary();
    if (!dict.has_value()) {
        ui_->useUserDict->setChecked(false);
        return;
    }

    ui_->useUserDict->setChecked(dict->enabled());
    for (const auto& entry : dict->entries()) {
        appendRow(QString::fromStdString(entry.word()),
                  QString::fromStdString(entry.reading()),
                  static_cast<int>(entry.word_class()), entry.priority());
    }
}

void DictionaryTabController::saveToConfig() {
    if (!context_.server) return;

    ui_->userDictViewer->setFocus();

    hazkey::dictionary::CurrentUserDictionary dict;
    dict.set_enabled(ui_->useUserDict->isChecked());
    for (int row = 0; row < model_->rowCount(); ++row) {
        const QString word = model_->item(row, kColumnWord)->text().trimmed();
        const QString reading =
            model_->item(row, kColumnReading)->text().trimmed();
        if (word.isEmpty() || reading.isEmpty()) continue;

        const int wordClass =
            model_->item(row, kColumnWordClass)->data(Qt::UserRole).toInt();
        bool ok = false;
        int priority = model_->item(row, kColumnPriority)->text().toInt(&ok);
        if (!ok) priority = kDefaultPriority;
        priority = qBound(0, priority, 100);

        auto* entry = dict.add_entries();
        entry->set_word(word.toStdString());
        entry->set_reading(reading.toStdString());
        entry->set_word_class(
            static_cast<UserDictionaryEntry::WordClass>(wordClass));
        entry->set_priority(priority);
    }

    context_.server->setUserDictionary(dict);
}

void DictionaryTabController::onNewEntry() {
    appendRow("", "", UserDictionaryEntry::NOUN, kDefaultPriority);
    const int row = model_->rowCount() - 1;
    const QModelIndex index = model_->index(row, kColumnWord);
    ui_->userDictViewer->setCurrentIndex(index);
    ui_->userDictViewer->edit(index);
}

void DictionaryTabController::onDeleteEntry() {
    const QModelIndexList selected =
        ui_->userDictViewer->selectionModel()->selectedRows();
    if (selected.isEmpty()) return;

    QList<int> rows;
    rows.reserve(selected.size());
    for (const auto& index : selected) rows.append(index.row());
    std::sort(rows.begin(), rows.end(), std::greater<int>());
    for (const int row : rows) model_->removeRow(row);
}

void DictionaryTabController::onImport() {
    const QString path = QFileDialog::getOpenFileName(
        window_, tr("Import User Dictionary"), QString(),
        tr("Tab-separated values (*.tsv *.txt);;All files (*)"));
    if (path.isEmpty()) return;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QMessageBox::critical(window_, tr("Import Failed"),
                              tr("Could not open the selected file."));
        return;
    }

    if (model_->rowCount() > 0) {
        const auto reply = QMessageBox::question(
            window_, tr("Import User Dictionary"),
            tr("Replace the current entries with the imported file?\n"
               "Choose \"No\" to append the imported entries instead."),
            QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
        if (reply == QMessageBox::Cancel) return;
        if (reply == QMessageBox::Yes) {
            model_->removeRows(0, model_->rowCount());
        }
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    int imported = 0;
    while (!in.atEnd()) {
        if (appendRowFromTsvLine(in.readLine())) ++imported;
    }

    QMessageBox::information(window_, tr("Import Complete"),
                             tr("Imported %1 entries.").arg(imported));
}

void DictionaryTabController::onExport() {
    const QString path = QFileDialog::getSaveFileName(
        window_, tr("Export User Dictionary"), "user_dictionary.tsv",
        tr("Tab-separated values (*.tsv);;All files (*)"));
    if (path.isEmpty()) return;

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QMessageBox::critical(window_, tr("Export Failed"),
                              tr("Could not write to the selected file."));
        return;
    }

    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    for (int row = 0; row < model_->rowCount(); ++row) {
        const QString word = model_->item(row, kColumnWord)->text();
        const QString reading = model_->item(row, kColumnReading)->text();
        const int wordClass =
            model_->item(row, kColumnWordClass)->data(Qt::UserRole).toInt();
        const QString priority = model_->item(row, kColumnPriority)->text();
        out << word << '\t' << reading << '\t' << wordClass << '\t'
            << priority << '\n';
    }
}

}  // namespace hazkey::settings
