import Foundation

enum ClipboardShelfRelativeTimeFormatter {
    private static func makeRelativeFormatter() -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    private static func makeAbsoluteFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }

    static func string(from date: Date, now: Date = Date()) -> String {
        let age = now.timeIntervalSince(date)

        if age < 60 * 60 * 24 {
            return makeRelativeFormatter().localizedString(for: date, relativeTo: now)
        }

        return makeAbsoluteFormatter().string(from: date)
    }
}
