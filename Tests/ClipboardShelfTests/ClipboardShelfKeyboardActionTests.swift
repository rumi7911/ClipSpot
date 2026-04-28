import AppKit
import XCTest
@testable import ClipboardShelf

final class ClipboardShelfKeyboardActionTests: XCTestCase {
    func testArrowKeysMapToSelectionMovementWithoutModifiers() {
        XCTAssertEqual(
            ClipboardShelfKeyboardAction.action(
                keyCode: 126,
                charactersIgnoringModifiers: nil,
                modifierFlags: []
            ),
            .moveUp
        )
        XCTAssertEqual(
            ClipboardShelfKeyboardAction.action(
                keyCode: 125,
                charactersIgnoringModifiers: nil,
                modifierFlags: []
            ),
            .moveDown
        )
    }

    func testModifiedArrowKeysAreIgnored() {
        XCTAssertNil(
            ClipboardShelfKeyboardAction.action(
                keyCode: 126,
                charactersIgnoringModifiers: nil,
                modifierFlags: [.command]
            )
        )
    }

    func testReturnEscapeAndCommandFMapToPanelActions() {
        XCTAssertEqual(
            ClipboardShelfKeyboardAction.action(
                keyCode: 36,
                charactersIgnoringModifiers: "\r",
                modifierFlags: []
            ),
            .copySelected
        )
        XCTAssertEqual(
            ClipboardShelfKeyboardAction.action(
                keyCode: 53,
                charactersIgnoringModifiers: "\u{1b}",
                modifierFlags: []
            ),
            .close
        )
        XCTAssertEqual(
            ClipboardShelfKeyboardAction.action(
                keyCode: 3,
                charactersIgnoringModifiers: "f",
                modifierFlags: [.command]
            ),
            .focusSearch
        )
    }
}
