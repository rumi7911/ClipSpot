import AppKit
import Foundation

protocol PasteboardReading {
    var changeCount: Int { get }
    func capturedContents() -> [ClipboardContent]
}

struct SystemPasteboardClient: PasteboardReading {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func capturedContents() -> [ClipboardContent] {
        let fileURLs = pasteboard
            .readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            )?
            .compactMap { object -> URL? in
                if let url = object as? URL, url.isFileURL {
                    return url
                }

                if let url = object as? NSURL, url.isFileURL {
                    return url as URL
                }

                return nil
            } ?? []

        if fileURLs.isEmpty == false {
            return fileURLs.map { .file(ClipboardFileReference(url: $0)) }
        }

        guard let text = pasteboard.string(forType: .string), text.isEmpty == false else {
            return []
        }

        return [.text(text)]
    }
}

protocol TimerControlling: AnyObject {
    func invalidate()
}

final class ScheduledTimer: NSObject, TimerControlling {
    private var timer: Timer?
    private let action: () -> Void

    init(interval: TimeInterval, action: @escaping () -> Void) {
        self.action = action
        super.init()
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(fire), userInfo: nil, repeats: true)
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func fire() {
        action()
    }
}

final class PasteboardMonitor {
    typealias CaptureHandler = ([ClipboardContent]) -> Void

    private let pasteboard: PasteboardReading
    private let pollInterval: TimeInterval
    private let makeTimer: (TimeInterval, @escaping () -> Void) -> TimerControlling
    private let onTextCaptured: CaptureHandler
    private let shouldCapture: () -> Bool

    private var timer: TimerControlling?
    private var lastChangeCount: Int

    init(
        pasteboard: PasteboardReading = SystemPasteboardClient(),
        pollInterval: TimeInterval = 0.75,
        makeTimer: @escaping (TimeInterval, @escaping () -> Void) -> TimerControlling = PasteboardMonitor.defaultTimer,
        shouldCapture: @escaping () -> Bool = { true },
        onTextCaptured: @escaping CaptureHandler
    ) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.makeTimer = makeTimer
        self.shouldCapture = shouldCapture
        self.onTextCaptured = onTextCaptured
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastChangeCount = pasteboard.changeCount
        timer = makeTimer(pollInterval) { [weak self] in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        guard shouldCapture() else {
            return
        }

        let contents = pasteboard.capturedContents()
        guard contents.isEmpty == false else {
            return
        }

        onTextCaptured(contents)
    }

    private static func defaultTimer(interval: TimeInterval, action: @escaping () -> Void) -> TimerControlling {
        ScheduledTimer(interval: interval, action: action)
    }
}
