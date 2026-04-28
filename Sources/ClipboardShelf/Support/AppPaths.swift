import Foundation

enum AppPaths {
    static let appDirectoryName = "ClipboardShelf"
    static let historyFileName = "history.json"

    static func applicationSupportDirectory(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        return baseDirectory.appendingPathComponent(appDirectoryName, isDirectory: true)
    }

    static func historyFileURL(fileManager: FileManager = .default) -> URL {
        applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent(historyFileName, isDirectory: false)
    }
}
