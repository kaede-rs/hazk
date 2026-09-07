import Foundation
import KanaKanjiConverterModule
import SwiftUtils

enum UserDictionaryWordClass: Int, CaseIterable, Sendable {
    case noun = 1  // 一般名詞
    case properNoun = 2  // 固有名詞
    case personName = 3  // 人名(姓名一体)
    case personFamilyName = 4  // 人名(姓)
    case personGivenName = 5  // 人名(名)
    case organizationName = 6  // 組織・団体名
    case placeName = 7  // 地名

    var cid: Int {
        switch self {
        case .noun: return CIDData.一般名詞.cid
        case .properNoun: return CIDData.固有名詞.cid
        case .personName: return CIDData.人名一般.cid
        case .personFamilyName: return CIDData.人名姓.cid
        case .personGivenName: return CIDData.人名名.cid
        case .organizationName: return CIDData.固有名詞組織.cid
        case .placeName: return CIDData.地名一般.cid
        }
    }
}

struct UserDictionaryEntry: Equatable, Sendable {
    var word: String
    var reading: String
    var wordClass: UserDictionaryWordClass
    var priority: Int

    init(word: String, reading: String, wordClass: UserDictionaryWordClass, priority: Int) {
        self.word = word
        self.reading = reading
        self.wordClass = wordClass
        self.priority = min(max(priority, 0), 100)
    }
}

final class UserDictionaryStore {
    private(set) var enabled: Bool
    private(set) var entries: [UserDictionaryEntry]

    init() {
        let loaded = Self.load()
        self.enabled = loaded.enabled
        self.entries = loaded.entries
    }

    static func getDictionaryFileURL() -> URL {
        HazkeyServerConfig.getConfigDirectory()
            .appendingPathComponent("dictionary", isDirectory: true)
            .appendingPathComponent("user.tsv", isDirectory: false)
    }

    private static func load() -> (enabled: Bool, entries: [UserDictionaryEntry]) {
        let path = getDictionaryFileURL()
        guard let content = try? String(contentsOf: path, encoding: .utf8) else {
            return (false, [])
        }

        var enabled = true
        var entries: [UserDictionaryEntry] = []

        for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .init(charactersIn: "\r"))
            if line.isEmpty { continue }
            if line.hasPrefix("#enabled=") {
                enabled = line.hasSuffix("true")
                continue
            }
            if line.hasPrefix("#") { continue }

            let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cols.count >= 2 else { continue }
            let word = String(cols[0])
            let reading = String(cols[1])
            let wordClassRaw = cols.count >= 3 ? Int(cols[2]) ?? 1 : 1
            let priority = cols.count >= 4 ? Int(cols[3]) ?? 50 : 50
            let wordClass = UserDictionaryWordClass(rawValue: wordClassRaw) ?? .noun

            guard !word.isEmpty, !reading.isEmpty else { continue }
            entries.append(
                UserDictionaryEntry(
                    word: word, reading: reading, wordClass: wordClass, priority: priority))
        }

        return (enabled, entries)
    }

    func save(enabled: Bool, entries: [UserDictionaryEntry]) throws {
        let path = Self.getDictionaryFileURL()
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(), withIntermediateDirectories: true)

        var lines = ["#enabled=\(enabled)"]
        for entry in entries {
            let sanitizedWord = entry.word.replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "\n", with: "")
            let sanitizedReading = entry.reading.replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "\n", with: "")
            lines.append(
                "\(sanitizedWord)\t\(sanitizedReading)\t\(entry.wordClass.rawValue)\t\(entry.priority)"
            )
        }

        let data = (lines.joined(separator: "\n") + "\n")
        try data.write(to: path, atomically: true, encoding: .utf8)

        self.enabled = enabled
        self.entries = entries
    }

    func makeDicdataElements() -> [DicdataElement] {
        guard enabled else { return [] }
        return entries.compactMap { entry -> DicdataElement? in
            let word = entry.word.trimmingCharacters(in: .whitespacesAndNewlines)
            let reading = entry.reading.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !word.isEmpty, !reading.isEmpty else { return nil }

            let normalized = PValue(entry.priority) / 100.0
            let value: PValue = -15.0 + normalized * 14.0

            return DicdataElement(
                word: word,
                ruby: reading.toKatakana(),
                cid: entry.wordClass.cid,
                mid: MIDData.一般.mid,
                value: value,
                metadata: [.isFromUserDictionary]
            )
        }
    }
}
