import AppKit

@MainActor
final class ClipboardShelfAppDelegate: NSObject, NSApplicationDelegate {
    private let store = ClipboardStore()
    private var monitor: PasteboardMonitor?
    private var statusBarController: StatusBarController?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()

        monitor = PasteboardMonitor { [weak self] contents in
            self?.store.handleCapturedContents(contents)
        }
        monitor?.start()

        statusBarController = StatusBarController(store: store)
        hotKey = GlobalHotKey.clipShelfDefault { [weak self] in
            Task { @MainActor in
                self?.statusBarController?.togglePopoverFromHotKey()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
    }
}
