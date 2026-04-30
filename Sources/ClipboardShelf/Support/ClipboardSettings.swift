import Carbon
import Foundation

struct ClipSpotSettings: Codable, Equatable {
    var launchAtLogin: Bool
    var startMonitoringAtLaunch: Bool
    var isMonitoringPaused: Bool
    var historyLimit: Int
    var ignoreConsecutiveDuplicates: Bool
    var showMediaPreviews: Bool
    var confirmBeforeDeletingItem: Bool
    var confirmBeforeClearingHistory: Bool
    var hotKeyShortcut: HotKeyShortcut
    var excludedApps: [ExcludedApp]

    static let `default` = ClipSpotSettings(
        launchAtLogin: false,
        startMonitoringAtLaunch: true,
        isMonitoringPaused: false,
        historyLimit: 25,
        ignoreConsecutiveDuplicates: true,
        showMediaPreviews: true,
        confirmBeforeDeletingItem: true,
        confirmBeforeClearingHistory: true,
        hotKeyShortcut: .optionCommandV,
        excludedApps: []
    )
}

struct ExcludedApp: Codable, Equatable, Identifiable {
    let bundleIdentifier: String
    var displayName: String

    var id: String {
        bundleIdentifier
    }
}

enum HotKeyShortcut: String, Codable, CaseIterable, Identifiable {
    case disabled
    case optionCommandV
    case optionCommandSpace
    case commandShiftV
    case controlOptionSpace

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .optionCommandV:
            return "Option + Command + V"
        case .optionCommandSpace:
            return "Option + Command + Space"
        case .commandShiftV:
            return "Command + Shift + V"
        case .controlOptionSpace:
            return "Control + Option + Space"
        }
    }

    var keyCode: UInt32? {
        switch self {
        case .disabled:
            return nil
        case .optionCommandV, .commandShiftV:
            return UInt32(kVK_ANSI_V)
        case .optionCommandSpace, .controlOptionSpace:
            return UInt32(kVK_Space)
        }
    }

    var modifiers: UInt32? {
        switch self {
        case .disabled:
            return nil
        case .optionCommandV, .optionCommandSpace:
            return UInt32(optionKey | cmdKey)
        case .commandShiftV:
            return UInt32(cmdKey | shiftKey)
        case .controlOptionSpace:
            return UInt32(controlKey | optionKey)
        }
    }
}
