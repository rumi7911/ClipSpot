import XCTest
@testable import ClipboardShelf

final class PersistenceServiceTests: XCTestCase {
    func testSaveAndLoadRoundTripsClipboardItems() throws {
        let historyURL = try makeHistoryURL()
        let service = PersistenceService(historyFileURL: historyURL)
        let items = [
            ClipboardItem(
                id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                text: "First item",
                capturedAt: Date(timeIntervalSince1970: 10)
            ),
            ClipboardItem(
                id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
                text: "Second item",
                capturedAt: Date(timeIntervalSince1970: 20)
            )
        ]

        try service.saveHistory(items)

        XCTAssertEqual(try service.loadHistory(), items)
    }

    func testLoadReturnsEmptyArrayWhenHistoryFileDoesNotExist() throws {
        let historyURL = try makeHistoryURL()
        let service = PersistenceService(historyFileURL: historyURL)

        XCTAssertEqual(try service.loadHistory(), [])
    }

    func testLoadSupportsLegacyTextOnlyHistory() throws {
        let historyURL = try makeHistoryURL()
        let service = PersistenceService(historyFileURL: historyURL)
        let legacyJSON = """
        [
          {
            "id": "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
            "text": "Legacy text clip",
            "capturedAt": "1970-01-01T00:00:10Z"
          }
        ]
        """

        try FileManager.default.createDirectory(at: historyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(legacyJSON.utf8).write(to: historyURL)

        XCTAssertEqual(
            try service.loadHistory(),
            [
                ClipboardItem(
                    id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                    text: "Legacy text clip",
                    capturedAt: Date(timeIntervalSince1970: 10)
                )
            ]
        )
    }

    private func makeHistoryURL(file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create temporary directory: \(error)", file: file, line: line)
            throw error
        }

        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        return directory.appendingPathComponent("history.json", isDirectory: false)
    }
}
