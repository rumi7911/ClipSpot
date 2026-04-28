import SwiftUI

enum ClipboardShelfTheme {
    static let backgroundTop = Color(red: 0.16, green: 0.16, blue: 0.17)
    static let backgroundBottom = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let panel = Color.white.opacity(0.085)
    static let panelElevated = Color.white.opacity(0.145)
    static let panelStroke = Color.white.opacity(0.20)
    static let accent = Color(red: 0.93, green: 0.87, blue: 0.72)
    static let accentMuted = Color(red: 0.58, green: 0.55, blue: 0.49)
    static let textPrimary = Color(red: 0.97, green: 0.97, blue: 0.95)
    static let textSecondary = Color(red: 0.74, green: 0.74, blue: 0.72)
    static let textTertiary = Color(red: 0.54, green: 0.54, blue: 0.53)
    static let warning = Color(red: 1.00, green: 0.70, blue: 0.34)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.22, blue: 0.23),
            Color(red: 0.10, green: 0.10, blue: 0.11),
            backgroundBottom
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tileGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.135),
            Color.white.opacity(0.075)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tileHoverGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.19),
            Color.white.opacity(0.105)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tileHighlightGradient = LinearGradient(
        colors: [
            accent.opacity(0.24),
            Color.white.opacity(0.11)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
