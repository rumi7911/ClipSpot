import AppKit
import Combine
import Foundation

protocol PasteboardWriting {
    func write(string: String)
    func write(fileURL: URL)
}

struct SystemPasteboardWriter: PasteboardWriting {
    func write(string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    func write(fileURL: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSURL])
    }
}

final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem]
    @Published private(set) var errorMessage: String?

    private let persistenceService: ClipboardHistoryPersisting
    private let pasteboardWriter: PasteboardWriting
    private let fileManager: FileManager
    private let now: () -> Date
    private var settings: ClipSpotSettings

    init(
        persistenceService: ClipboardHistoryPersisting = PersistenceService(),
        pasteboardWriter: PasteboardWriting = SystemPasteboardWriter(),
        fileManager: FileManager = .default,
        settings: ClipSpotSettings = .default,
        now: @escaping () -> Date = Date.init,
        initialItems: [ClipboardItem] = []
    ) {
        self.persistenceService = persistenceService
        self.pasteboardWriter = pasteboardWriter
        self.fileManager = fileManager
        self.settings = settings
        self.now = now
        self.items = initialItems
    }

    func load() {
        do {
            items = try persistenceService.loadHistory()
            errorMessage = nil
        } catch {
            items = []
            errorMessage = "Couldn't load clipboard history."
        }
    }

    func handleCapturedText(_ text: String) {
        handleCapturedContent(.text(text))
    }

    func handleCapturedContents(_ contents: [ClipboardContent]) {
        contents.reversed().forEach(handleCapturedContent(_:))
    }

    func handleCapturedContent(_ content: ClipboardContent) {
        guard content.isCapturable else {
            return
        }

        if settings.ignoreConsecutiveDuplicates,
           items.first?.content == content {
            return
        }

        items.insert(ClipboardItem(content: content, capturedAt: now()), at: 0)
        trimHistoryIfNeeded()
        persistHistory()
    }

    func applySettings(_ settings: ClipSpotSettings) {
        self.settings = settings
        let originalCount = items.count
        trimHistoryIfNeeded()

        if items.count != originalCount {
            persistHistory()
        }
    }

    func copyItem(_ item: ClipboardItem) {
        switch item.content {
        case .text(let text):
            pasteboardWriter.write(string: text)
        case .file(let file):
            guard fileManager.fileExists(atPath: file.url.path) else {
                errorMessage = "\(file.url.lastPathComponent) no longer exists."
                return
            }

            pasteboardWriter.write(fileURL: file.url)
        }

        if let existingIndex = items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = items.remove(at: existingIndex)
            updatedItem.capturedAt = now()
            items.insert(updatedItem, at: 0)
        } else {
            items.insert(ClipboardItem(content: item.content, capturedAt: now()), at: 0)
            trimHistoryIfNeeded()
        }

        persistHistory()
    }

    func clearHistory() {
        items.removeAll()
        persistHistory()
    }

    func removeItem(_ item: ClipboardItem) {
        let originalCount = items.count
        items.removeAll { $0.id == item.id }

        guard items.count != originalCount else {
            return
        }

        persistHistory()
    }

    var staleFileReferenceCount: Int {
        items.filter(isStaleFileReference(_:)).count
    }

    func removeStaleFileReferences() {
        let originalCount = items.count
        items.removeAll(where: isStaleFileReference(_:))

        guard items.count != originalCount else {
            return
        }

        persistHistory()
    }

    func filteredItems(query: String, contentFilter: ClipboardContentFilter = .all) -> [ClipboardItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchingTypeItems = items.filter { contentFilter.matches($0.content) }

        guard trimmedQuery.isEmpty == false else {
            return matchingTypeItems
        }

        return matchingTypeItems.filter { $0.searchableText.localizedCaseInsensitiveContains(trimmedQuery) }
    }

    private func trimHistoryIfNeeded() {
        guard items.count > settings.historyLimit else {
            return
        }

        items = Array(items.prefix(settings.historyLimit))
    }

    private func isStaleFileReference(_ item: ClipboardItem) -> Bool {
        guard case .file(let file) = item.content else {
            return false
        }

        return fileManager.fileExists(atPath: file.url.path) == false
    }

    private func persistHistory() {
        do {
            try persistenceService.saveHistory(items)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't save clipboard history."
        }
    }
}

private extension ClipboardContent {
    var isCapturable: Bool {
        switch self {
        case .text(let text):
            return text.isEmpty == false
        case .file(let file):
            return file.url.isFileURL
        }
    }
}
