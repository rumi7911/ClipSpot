import XCTest
@testable import ClipboardShelf

final class ClipboardContentPreviewTests: XCTestCase {
    func testImageFilesExposeImagePreview() {
        let url = URL(fileURLWithPath: "/tmp/photo.png")
        let content = ClipboardContent.file(ClipboardFileReference(url: url, kind: .image))

        XCTAssertEqual(content.mediaPreview, .image(url))
    }

    func testVideoFilesExposeVideoPreview() {
        let url = URL(fileURLWithPath: "/tmp/movie.mov")
        let content = ClipboardContent.file(ClipboardFileReference(url: url, kind: .video))

        XCTAssertEqual(content.mediaPreview, .video(url))
    }

    func testTextAndNonMediaFilesDoNotExposeMediaPreview() {
        XCTAssertNil(ClipboardContent.text("Plain text").mediaPreview)

        let document = ClipboardContent.file(
            ClipboardFileReference(url: URL(fileURLWithPath: "/tmp/report.pdf"), kind: .document)
        )
        XCTAssertNil(document.mediaPreview)
    }

    func testOnlyFileContentExposesRevealInFinderURL() {
        let url = URL(fileURLWithPath: "/tmp/report.pdf")

        XCTAssertEqual(
            ClipboardContent.file(ClipboardFileReference(url: url, kind: .document)).revealInFinderURL,
            url
        )
        XCTAssertNil(ClipboardContent.text("Plain text").revealInFinderURL)
    }
}
