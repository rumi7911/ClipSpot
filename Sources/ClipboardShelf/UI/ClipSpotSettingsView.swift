import AppKit
import SwiftUI

struct ClipSpotSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var store: ClipboardStore

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "slider.horizontal.3")
                }

            clipboardTab
                .tabItem {
                    Label("Clipboard", systemImage: "document.on.clipboard")
                }

            hotKeyTab
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }

            excludedAppsTab
                .tabItem {
                    Label("Excluded Apps", systemImage: "app.badge")
                }

            advancedTab
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(minWidth: 620, minHeight: 460)
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                Toggle("Monitor clipboard on launch", isOn: startMonitoringBinding)
                Text("If disabled, clipboard monitoring stays off until you turn it back on after launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Safety") {
                Toggle("Confirm before deleting a clip", isOn: confirmDeleteBinding)
                Toggle("Confirm before clearing history", isOn: confirmClearBinding)
            }

            if let statusMessage = settingsStore.statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var clipboardTab: some View {
        Form {
            Section("Behavior") {
                Toggle("Pause clipboard monitoring", isOn: monitoringPausedBinding)
                Toggle("Ignore consecutive duplicates", isOn: ignoreDuplicatesBinding)
                Toggle("Show media previews", isOn: showMediaPreviewsBinding)
            }

            Section("History") {
                Stepper(value: historyLimitBinding, in: 10...200) {
                    HStack {
                        Text("History limit")
                        Spacer()
                        Text("\(settingsStore.settings.historyLimit) items")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var hotKeyTab: some View {
        Form {
            Section("Global Shortcut") {
                Picker("Shortcut", selection: hotKeyShortcutBinding) {
                    ForEach(HotKeyShortcut.allCases) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }

                Text("This shortcut opens or closes the ClipSpot popover from anywhere on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var excludedAppsTab: some View {
        Form {
            Section("Excluded Apps") {
                Text("ClipSpot ignores clipboard captures while one of these apps is frontmost.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settingsStore.settings.excludedApps.isEmpty {
                    Text("No excluded apps yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settingsStore.settings.excludedApps) { app in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.displayName)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Remove") {
                                settingsStore.removeExcludedApp(app)
                            }
                        }
                    }
                }

                Button("Pick App...") {
                    settingsStore.importExcludedApp()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var advancedTab: some View {
        Form {
            Section("Maintenance") {
                Button("Clear history") {
                    store.clearHistory()
                }

                Button("Remove stale media references") {
                    store.removeStaleFileReferences()
                }

                Button("Reveal storage location") {
                    settingsStore.revealStorageLocation()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.launchAtLogin },
            set: { settingsStore.settings.launchAtLogin = $0 }
        )
    }

    private var startMonitoringBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.startMonitoringAtLaunch },
            set: { settingsStore.settings.startMonitoringAtLaunch = $0 }
        )
    }

    private var monitoringPausedBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.isMonitoringPaused },
            set: { settingsStore.settings.isMonitoringPaused = $0 }
        )
    }

    private var ignoreDuplicatesBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.ignoreConsecutiveDuplicates },
            set: { settingsStore.settings.ignoreConsecutiveDuplicates = $0 }
        )
    }

    private var showMediaPreviewsBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.showMediaPreviews },
            set: { settingsStore.settings.showMediaPreviews = $0 }
        )
    }

    private var confirmDeleteBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.confirmBeforeDeletingItem },
            set: { settingsStore.settings.confirmBeforeDeletingItem = $0 }
        )
    }

    private var confirmClearBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.confirmBeforeClearingHistory },
            set: { settingsStore.settings.confirmBeforeClearingHistory = $0 }
        )
    }

    private var hotKeyShortcutBinding: Binding<HotKeyShortcut> {
        Binding(
            get: { settingsStore.settings.hotKeyShortcut },
            set: { settingsStore.settings.hotKeyShortcut = $0 }
        )
    }

    private var historyLimitBinding: Binding<Int> {
        Binding(
            get: { settingsStore.settings.historyLimit },
            set: { settingsStore.settings.historyLimit = min(max($0, 10), 200) }
        )
    }
}
