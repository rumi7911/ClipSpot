import XCTest
@testable import ClipboardShelf

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testPersistsAndReloadsSettings() {
        let suiteName = "clipspot.settings.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(userDefaults: defaults, storageKey: "settings")
        store.settings.historyLimit = 80
        store.settings.hotKeyShortcut = .commandShiftV
        store.settings.excludedApps = [ExcludedApp(bundleIdentifier: "com.example.preview", displayName: "Preview")]

        let restoredStore = SettingsStore(userDefaults: defaults, storageKey: "settings")

        XCTAssertEqual(restoredStore.settings.historyLimit, 80)
        XCTAssertEqual(restoredStore.settings.hotKeyShortcut, .commandShiftV)
        XCTAssertEqual(restoredStore.settings.excludedApps, [ExcludedApp(bundleIdentifier: "com.example.preview", displayName: "Preview")])
    }

    func testShouldCaptureRespectsPauseAndExcludedApps() {
        let suiteName = "clipspot.settings.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SettingsStore(userDefaults: defaults, storageKey: "settings")
        store.addExcludedApp(bundleIdentifier: "com.example.preview", displayName: "Preview")

        XCTAssertFalse(store.shouldCapture(frontmostBundleIdentifier: "com.example.preview"))
        XCTAssertTrue(store.shouldCapture(frontmostBundleIdentifier: "com.example.notes"))

        store.settings.isMonitoringPaused = true

        XCTAssertFalse(store.shouldCapture(frontmostBundleIdentifier: "com.example.notes"))
    }
}
