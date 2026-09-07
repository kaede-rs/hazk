#ifndef HAZKEY_SETTINGS_CONTROLLERS_DICTIONARY_TAB_CONTROLLER_H_
#define HAZKEY_SETTINGS_CONTROLLERS_DICTIONARY_TAB_CONTROLLER_H_

#include <QObject>

#include "controllers/tab_context.h"

class QWidget;
class QStandardItemModel;

namespace Ui {
class MainWindow;
}

namespace hazkey::settings {

class DictionaryTabController : public QObject {
    Q_OBJECT

   public:
    DictionaryTabController(Ui::MainWindow* ui, QWidget* window,
                             QObject* parent);
    void setContext(const TabContext& context);
    void connectSignals();
    void loadFromConfig();
    void saveToConfig();

   private slots:
    void onNewEntry();
    void onDeleteEntry();
    void onImport();
    void onExport();

   private:
    void appendRow(const QString& word, const QString& reading,
                   int wordClass, int priority);
    bool appendRowFromTsvLine(const QString& line);

    Ui::MainWindow* ui_;
    QWidget* window_;
    TabContext context_;
    QStandardItemModel* model_;
};

}  // namespace hazkey::settings

#endif  // HAZKEY_SETTINGS_CONTROLLERS_DICTIONARY_TAB_CONTROLLER_H_
