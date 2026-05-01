import AppKit
import XCTest
@testable import ClipboardShelf

@MainActor
final class ClipboardShelfAppDelegateTests: XCTestCase {
    func testAppDelegateRespondsToSettingsActionSelector() {
        let delegate = ClipboardShelfAppDelegate()

        XCTAssertTrue((delegate as AnyObject).responds(to: #selector(ClipboardShelfAppDelegate.showSettingsWindow(_:))))
    }

    func testShowSettingsWindowCreatesSingleSettingsWindow() {
        _ = NSApplication.shared
        let delegate = ClipboardShelfAppDelegate()
        NSApp.delegate = delegate
        defer {
            NSApp.windows
                .filter { $0.title == "ClipSpot Settings" }
                .forEach { $0.close() }
            NSApp.delegate = nil
        }

        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        delegate.showSettingsWindow(nil)
        delegate.showSettingsWindow(nil)

        XCTAssertEqual(NSApp.windows.filter { $0.title == "ClipSpot Settings" }.count, 1)
    }
}
