import XCTest
@testable import ClipboardShelf

final class ClipboardStoreTests: XCTestCase {
    func testInsertingNewItemAddsItToFront() {
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            now: { Date(timeIntervalSince1970: 100) }
        )

        store.handleCapturedText("First item")

        XCTAssertEqual(store.items.map(\.text), ["First item"])
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["First item"])
    }

    func testRejectsConsecutiveDuplicates() {
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [ClipboardItem(text: "Repeat me", capturedAt: Date(timeIntervalSince1970: 1))]
        )

        store.handleCapturedText("Repeat me")

        XCTAssertEqual(store.items.map(\.text), ["Repeat me"])
        XCTAssertTrue(persistence.savedSnapshots.isEmpty)
    }

    func testTrimsHistoryBeyondTwentyFiveItems() {
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            now: { Date(timeIntervalSince1970: 1) }
        )

        for index in 0..<26 {
            store.handleCapturedText("Item \(index)")
        }

        XCTAssertEqual(store.items.count, 25)
        XCTAssertEqual(store.items.first?.text, "Item 25")
        XCTAssertEqual(store.items.last?.text, "Item 1")
    }

    func testClearHistoryRemovesAllItemsAndPersists() {
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [ClipboardItem(text: "One"), ClipboardItem(text: "Two")]
        )

        store.clearHistory()

        XCTAssertTrue(store.items.isEmpty)
        XCTAssertEqual(persistence.savedSnapshots.last, [])
    }

    func testRemoveItemDeletesSingleEntryAndPersists() {
        let persistence = PersistenceSpy()
        let first = ClipboardItem(text: "One")
        let second = ClipboardItem(text: "Two")
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [first, second]
        )

        store.removeItem(first)

        XCTAssertEqual(store.items.map(\.text), ["Two"])
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["Two"])
    }

    func testFilteringItemsByQueryIsCaseInsensitive() {
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "Alpha Beta"),
                ClipboardItem(text: "Gamma"),
                ClipboardItem(text: "delta")
            ]
        )

        XCTAssertEqual(store.filteredItems(query: "ALPHA").map(\.text), ["Alpha Beta"])
        XCTAssertEqual(store.filteredItems(query: "ta").map(\.text), ["Alpha Beta", "delta"])
    }

    func testCopyItemWritesTextBackAndAvoidsDuplicateOnNextCapture() {
        let persistence = PersistenceSpy()
        let pasteboardWriter = PasteboardWriterSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: pasteboardWriter,
            now: { Date(timeIntervalSince1970: 500) },
            initialItems: [
                ClipboardItem(text: "Newest", capturedAt: Date(timeIntervalSince1970: 300)),
                ClipboardItem(text: "Older", capturedAt: Date(timeIntervalSince1970: 200))
            ]
        )

        store.copyItem(store.items[1])
        store.handleCapturedText("Older")

        XCTAssertEqual(pasteboardWriter.writes, ["Older"])
        XCTAssertEqual(store.items.map(\.text), ["Older", "Newest"])
        XCTAssertEqual(store.items.first?.capturedAt, Date(timeIntervalSince1970: 500))
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["Older", "Newest"])
    }

    func testCapturingFileReferenceAddsItToFront() throws {
        let fileURL = try makeTemporaryFile(name: "image.png")
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy()
        )

        store.handleCapturedContent(.file(ClipboardFileReference(url: fileURL, kind: .image)))

        XCTAssertEqual(store.items.first?.content, .file(ClipboardFileReference(url: fileURL, kind: .image)))
        XCTAssertEqual(persistence.savedSnapshots.last?.first?.content, .file(ClipboardFileReference(url: fileURL, kind: .image)))
    }

    func testCapturingMultipleFilesPreservesPasteboardOrder() {
        let firstURL = URL(fileURLWithPath: "/tmp/first.png")
        let secondURL = URL(fileURLWithPath: "/tmp/second.mov")
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy()
        )

        store.handleCapturedContents([
            .file(ClipboardFileReference(url: firstURL, kind: .image)),
            .file(ClipboardFileReference(url: secondURL, kind: .video))
        ])

        XCTAssertEqual(store.items.map(\.content), [
            .file(ClipboardFileReference(url: firstURL, kind: .image)),
            .file(ClipboardFileReference(url: secondURL, kind: .video))
        ])
    }


    func testCopyFileReferenceWritesURLWhenFileStillExists() throws {
        let fileURL = try makeTemporaryFile(name: "clip.mov")
        let pasteboardWriter = PasteboardWriterSpy()
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: pasteboardWriter,
            initialItems: [ClipboardItem(content: .file(ClipboardFileReference(url: fileURL, kind: .video)))]
        )

        store.copyItem(store.items[0])

        XCTAssertEqual(pasteboardWriter.fileURLWrites, [fileURL])
        XCTAssertNil(store.errorMessage)
    }

    func testCopyFileReferenceWorksWhenPathContainsSpaces() throws {
        let fileURL = try makeTemporaryFile(name: "clip with spaces.mov")
        let pasteboardWriter = PasteboardWriterSpy()
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: pasteboardWriter,
            initialItems: [ClipboardItem(content: .file(ClipboardFileReference(url: fileURL, kind: .video)))]
        )

        store.copyItem(store.items[0])

        XCTAssertEqual(pasteboardWriter.fileURLWrites, [fileURL])
        XCTAssertNil(store.errorMessage)
    }

    func testCopyFileReferenceShowsErrorWhenFileNoLongerExists() {
        let missingURL = URL(fileURLWithPath: "/tmp/missing-clip-file.mov")
        let pasteboardWriter = PasteboardWriterSpy()
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: pasteboardWriter,
            initialItems: [ClipboardItem(content: .file(ClipboardFileReference(url: missingURL, kind: .video)))]
        )

        store.copyItem(store.items[0])

        XCTAssertTrue(pasteboardWriter.fileURLWrites.isEmpty)
        XCTAssertEqual(store.errorMessage, "missing-clip-file.mov no longer exists.")
    }

    func testStaleFileReferenceCountIgnoresTextAndExistingFiles() throws {
        let existingURL = try makeTemporaryFile(name: "existing.png")
        let missingURL = URL(fileURLWithPath: "/tmp/missing-reference.png")
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "Keep text"),
                ClipboardItem(content: .file(ClipboardFileReference(url: existingURL, kind: .image))),
                ClipboardItem(content: .file(ClipboardFileReference(url: missingURL, kind: .image)))
            ]
        )

        XCTAssertEqual(store.staleFileReferenceCount, 1)
    }

    func testStaleFileReferenceCountTreatsExistingPathsWithSpacesAsValid() throws {
        let existingURL = try makeTemporaryFile(name: "existing image.png")
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(content: .file(ClipboardFileReference(url: existingURL, kind: .image)))
            ]
        )

        XCTAssertEqual(store.staleFileReferenceCount, 0)
    }

    func testRemoveStaleFileReferencesKeepsValidItemsAndPersists() throws {
        let existingURL = try makeTemporaryFile(name: "existing.mov")
        let missingURL = URL(fileURLWithPath: "/tmp/missing-reference.mov")
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "Keep text"),
                ClipboardItem(content: .file(ClipboardFileReference(url: missingURL, kind: .video))),
                ClipboardItem(content: .file(ClipboardFileReference(url: existingURL, kind: .video)))
            ]
        )

        store.removeStaleFileReferences()

        XCTAssertEqual(store.items.map(\.text), ["Keep text", "existing.mov"])
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["Keep text", "existing.mov"])
        XCTAssertNil(store.errorMessage)
    }

    func testFilteringMatchesFileNameAndPath() {
        let fileURL = URL(fileURLWithPath: "/Users/test/Movies/Product Demo.mov")
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "Alpha Beta"),
                ClipboardItem(content: .file(ClipboardFileReference(url: fileURL, kind: .video)))
            ]
        )

        XCTAssertEqual(store.filteredItems(query: "demo").map(\.content), [.file(ClipboardFileReference(url: fileURL, kind: .video))])
        XCTAssertEqual(store.filteredItems(query: "movies").map(\.content), [.file(ClipboardFileReference(url: fileURL, kind: .video))])
    }

    func testFilteringItemsByContentFilter() {
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "Text clip"),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/photo.png"), kind: .image))),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/movie.mov"), kind: .video))),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/report.pdf"), kind: .document))),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/folder"), kind: .folder)))
            ]
        )

        XCTAssertEqual(store.filteredItems(query: "", contentFilter: .all).map(\.text), [
            "Text clip",
            "photo.png",
            "movie.mov",
            "report.pdf",
            "folder"
        ])
        XCTAssertEqual(store.filteredItems(query: "", contentFilter: .text).map(\.text), ["Text clip"])
        XCTAssertEqual(store.filteredItems(query: "", contentFilter: .images).map(\.text), ["photo.png"])
        XCTAssertEqual(store.filteredItems(query: "", contentFilter: .videos).map(\.text), ["movie.mov"])
        XCTAssertEqual(store.filteredItems(query: "", contentFilter: .files).map(\.text), ["report.pdf", "folder"])
    }

    func testQueryFilteringCombinesWithContentFilter() {
        let store = ClipboardStore(
            persistenceService: PersistenceSpy(),
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "project notes"),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/project.png"), kind: .image))),
                ClipboardItem(content: .file(ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/project.mov"), kind: .video)))
            ]
        )

        XCTAssertEqual(store.filteredItems(query: "project", contentFilter: .images).map(\.text), ["project.png"])
        XCTAssertEqual(store.filteredItems(query: "notes", contentFilter: .images).map(\.text), [])
    }

    func testApplySettingsTrimsExistingItemsToNewHistoryLimit() {
        let persistence = PersistenceSpy()
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            initialItems: [
                ClipboardItem(text: "One"),
                ClipboardItem(text: "Two"),
                ClipboardItem(text: "Three")
            ]
        )

        var settings = ClipSpotSettings.default
        settings.historyLimit = 2
        store.applySettings(settings)

        XCTAssertEqual(store.items.map(\.text), ["One", "Two"])
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["One", "Two"])
    }

    func testDisablingDuplicateProtectionAllowsConsecutiveDuplicates() {
        let persistence = PersistenceSpy()
        var settings = ClipSpotSettings.default
        settings.ignoreConsecutiveDuplicates = false
        let store = ClipboardStore(
            persistenceService: persistence,
            pasteboardWriter: PasteboardWriterSpy(),
            settings: settings,
            initialItems: [ClipboardItem(text: "Repeat me", capturedAt: Date(timeIntervalSince1970: 1))]
        )

        store.handleCapturedText("Repeat me")

        XCTAssertEqual(store.items.map(\.text), ["Repeat me", "Repeat me"])
        XCTAssertEqual(persistence.savedSnapshots.last?.map(\.text), ["Repeat me", "Repeat me"])
    }

    private func makeTemporaryFile(name: String, file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(name, isDirectory: false)
            try Data("fixture".utf8).write(to: fileURL)

            addTeardownBlock {
                try? FileManager.default.removeItem(at: directory)
            }

            return fileURL
        } catch {
            XCTFail("Failed to create temporary file: \(error)", file: file, line: line)
            throw error
        }
    }
}

private final class PersistenceSpy: ClipboardHistoryPersisting {
    var loadResult: Result<[ClipboardItem], Error> = .success([])
    private(set) var savedSnapshots: [[ClipboardItem]] = []

    func loadHistory() throws -> [ClipboardItem] {
        try loadResult.get()
    }

    func saveHistory(_ items: [ClipboardItem]) throws {
        savedSnapshots.append(items)
    }
}

private final class PasteboardWriterSpy: PasteboardWriting {
    private(set) var writes: [String] = []
    private(set) var fileURLWrites: [URL] = []

    func write(string: String) {
        writes.append(string)
    }

    func write(fileURL: URL) {
        fileURLWrites.append(fileURL)
    }
}
