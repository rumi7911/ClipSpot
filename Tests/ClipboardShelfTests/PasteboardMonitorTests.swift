import XCTest
@testable import ClipboardShelf

final class PasteboardMonitorTests: XCTestCase {
    func testDetectsChangeCountChanges() {
        let pasteboard = PasteboardSpy(changeCount: 0, contents: [])
        var capturedContents: [ClipboardContent] = []
        let monitor = PasteboardMonitor(
            pasteboard: pasteboard,
            makeTimer: { _, _ in TimerSpy() }
        ) { capturedContents.append(contentsOf: $0) }

        pasteboard.contents = [.text("Copied text")]
        pasteboard.changeCount = 1
        monitor.poll()

        XCTAssertEqual(capturedContents, [.text("Copied text")])
    }

    func testIgnoresUnchangedPasteboardState() {
        let pasteboard = PasteboardSpy(changeCount: 3, contents: [.text("Stable text")])
        var capturedContents: [ClipboardContent] = []
        let monitor = PasteboardMonitor(
            pasteboard: pasteboard,
            makeTimer: { _, _ in TimerSpy() }
        ) { capturedContents.append(contentsOf: $0) }

        monitor.poll()

        XCTAssertTrue(capturedContents.isEmpty)
    }

    func testIgnoresNonTextContent() {
        let pasteboard = PasteboardSpy(changeCount: 0, contents: [])
        var capturedContents: [ClipboardContent] = []
        let monitor = PasteboardMonitor(
            pasteboard: pasteboard,
            makeTimer: { _, _ in TimerSpy() }
        ) { capturedContents.append(contentsOf: $0) }

        pasteboard.changeCount = 1
        monitor.poll()

        XCTAssertTrue(capturedContents.isEmpty)
    }

    func testForwardsNewlyCapturedTextOnce() {
        let pasteboard = PasteboardSpy(changeCount: 0, contents: [.text("Fresh text")])
        var capturedContents: [ClipboardContent] = []
        let monitor = PasteboardMonitor(
            pasteboard: pasteboard,
            makeTimer: { _, _ in TimerSpy() }
        ) { capturedContents.append(contentsOf: $0) }

        pasteboard.changeCount = 1
        monitor.poll()
        monitor.poll()

        XCTAssertEqual(capturedContents, [.text("Fresh text")])
    }

    func testForwardsCopiedFileReferences() {
        let fileURL = URL(fileURLWithPath: "/tmp/example.png")
        let pasteboard = PasteboardSpy(
            changeCount: 0,
            contents: [.file(ClipboardFileReference(url: fileURL, kind: .image))]
        )
        var capturedContents: [ClipboardContent] = []
        let monitor = PasteboardMonitor(
            pasteboard: pasteboard,
            makeTimer: { _, _ in TimerSpy() }
        ) { capturedContents.append(contentsOf: $0) }

        pasteboard.changeCount = 1
        monitor.poll()

        XCTAssertEqual(capturedContents, [.file(ClipboardFileReference(url: fileURL, kind: .image))])
    }
}

private final class PasteboardSpy: PasteboardReading {
    var changeCount: Int
    var contents: [ClipboardContent]

    init(changeCount: Int, contents: [ClipboardContent]) {
        self.changeCount = changeCount
        self.contents = contents
    }

    func capturedContents() -> [ClipboardContent] {
        contents
    }
}

private final class TimerSpy: TimerControlling {
    func invalidate() {}
}
