import SwiftUI

@main
struct ClipboardShelfApp: App {
    @NSApplicationDelegateAdaptor(ClipboardShelfAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
