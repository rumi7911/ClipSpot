import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: ClipSpotSettings {
        didSet {
            guard isRestoring == false else {
                return
            }

            persist()
        }
    }

    @Published private(set) var statusMessage: String?

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var isRestoring = false

    init(userDefaults: UserDefaults = .standard, storageKey: String = "clipspot.settings") {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        encoder = JSONEncoder()
        decoder = JSONDecoder()

        if let data = userDefaults.data(forKey: storageKey),
           let restoredSettings = try? decoder.decode(ClipSpotSettings.self, from: data) {
            settings = restoredSettings
        } else {
            settings = .default
        }
    }

    func syncLaunchAtLoginState(_ isEnabled: Bool) {
        guard settings.launchAtLogin != isEnabled else {
            return
        }

        isRestoring = true
        settings.launchAtLogin = isEnabled
        isRestoring = false
        persist()
    }

    func addExcludedApp(bundleIdentifier: String, displayName: String) {
        guard bundleIdentifier.isEmpty == false else {
            return
        }

        let entry = ExcludedApp(bundleIdentifier: bundleIdentifier, displayName: displayName)
        guard settings.excludedApps.contains(entry) == false else {
            return
        }

        settings.excludedApps.append(entry)
        settings.excludedApps.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func removeExcludedApp(_ app: ExcludedApp) {
        settings.excludedApps.removeAll { $0.id == app.id }
    }

    func importExcludedApp() {
        let panel = NSOpenPanel()
        panel.title = "Choose an app to exclude"
        panel.allowedContentTypes = [UTType.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK,
              let appURL = panel.url,
              let bundle = Bundle(url: appURL),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return
        }

        let displayName =
            bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appURL.deletingPathExtension().lastPathComponent

        addExcludedApp(bundleIdentifier: bundleIdentifier, displayName: displayName)
    }

    func shouldCapture(frontmostBundleIdentifier: String?) -> Bool {
        guard settings.isMonitoringPaused == false else {
            return false
        }

        guard let frontmostBundleIdentifier else {
            return true
        }

        return settings.excludedApps.contains { $0.bundleIdentifier == frontmostBundleIdentifier } == false
    }

    func revealStorageLocation() {
        let directoryURL = AppPaths.applicationSupportDirectory()
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([directoryURL])
    }

    func setStatusMessage(_ message: String?) {
        statusMessage = message
    }

    private func persist() {
        guard let data = try? encoder.encode(settings) else {
            statusMessage = "Couldn't save settings."
            return
        }

        userDefaults.set(data, forKey: storageKey)
        statusMessage = nil
    }
}
