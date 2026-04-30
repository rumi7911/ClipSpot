import AppKit
import Combine

@MainActor
final class ClipboardShelfAppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore: SettingsStore
    let store: ClipboardStore
    private var monitor: PasteboardMonitor?
    private var statusBarController: StatusBarController?
    private var hotKey: GlobalHotKey?
    private let launchAtLoginController: LaunchAtLoginControlling
    private var settingsObserver: AnyCancellable?

    override init() {
        let settingsStore = SettingsStore()
        self.settingsStore = settingsStore
        store = ClipboardStore(settings: settingsStore.settings)
        launchAtLoginController = LaunchAtLoginController()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsStore.syncLaunchAtLoginState(launchAtLoginController.currentStatus())
        store.load()
        store.applySettings(settingsStore.settings)

        monitor = PasteboardMonitor(shouldCapture: { [weak self] in
            guard let self else {
                return true
            }

            return self.settingsStore.shouldCapture(
                frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            )
        }) { [weak self] contents in
            self?.store.handleCapturedContents(contents)
        }
        updateMonitorState(initialLaunch: true)

        statusBarController = StatusBarController(store: store, settingsStore: settingsStore)
        updateHotKey()

        settingsObserver = settingsStore.$settings
            .removeDuplicates()
            .sink { [weak self] settings in
                self?.store.applySettings(settings)
                self?.updateMonitorState(initialLaunch: false)
                self?.updateLaunchAtLogin(using: settings)
                self?.updateHotKey()
            }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
    }

    private func updateHotKey() {
        hotKey = GlobalHotKey.make(from: settingsStore.settings.hotKeyShortcut) { [weak self] in
            Task { @MainActor in
                self?.statusBarController?.togglePopoverFromHotKey()
            }
        }
    }

    private func updateMonitorState(initialLaunch: Bool) {
        let shouldMonitor: Bool

        if initialLaunch {
            shouldMonitor = settingsStore.settings.startMonitoringAtLaunch && settingsStore.settings.isMonitoringPaused == false
        } else {
            shouldMonitor = settingsStore.settings.isMonitoringPaused == false
        }

        if shouldMonitor {
            monitor?.start()
        } else {
            monitor?.stop()
        }
    }

    private func updateLaunchAtLogin(using settings: ClipSpotSettings) {
        do {
            try launchAtLoginController.setEnabled(settings.launchAtLogin)
            settingsStore.setStatusMessage(nil)
        } catch {
            settingsStore.setStatusMessage("Couldn't update launch at login.")
        }
    }
}
