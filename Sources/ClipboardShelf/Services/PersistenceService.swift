import Foundation

protocol ClipboardHistoryPersisting {
    func loadHistory() throws -> [ClipboardItem]
    func saveHistory(_ items: [ClipboardItem]) throws
}

struct PersistenceService: ClipboardHistoryPersisting {
    let historyFileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(historyFileURL: URL = AppPaths.historyFileURL(), fileManager: FileManager = .default) {
        self.historyFileURL = historyFileURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadHistory() throws -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: historyFileURL)
        return try decoder.decode([ClipboardItem].self, from: data)
    }

    func saveHistory(_ items: [ClipboardItem]) throws {
        let directoryURL = historyFileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try encoder.encode(items)
        try data.write(to: historyFileURL, options: .atomic)
    }
}
