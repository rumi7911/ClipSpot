import Foundation

struct ClipboardItem: Codable, Equatable, Identifiable {
    let id: UUID
    var content: ClipboardContent
    var capturedAt: Date

    init(id: UUID = UUID(), content: ClipboardContent, capturedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
    }

    init(id: UUID = UUID(), text: String, capturedAt: Date = Date()) {
        self.init(id: id, content: .text(text), capturedAt: capturedAt)
    }

    var text: String {
        content.displayTitle
    }

    var previewText: String {
        content.displayTitle.components(separatedBy: .newlines).first ?? content.displayTitle
    }

    var detailText: String {
        content.detailText
    }

    var searchableText: String {
        content.searchableText
    }

    var systemImageName: String {
        content.systemImageName
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case content
        case capturedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)

        if let content = try container.decodeIfPresent(ClipboardContent.self, forKey: .content) {
            self.content = content
        } else {
            let text = try container.decode(String.self, forKey: .text)
            content = .text(text)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(capturedAt, forKey: .capturedAt)
    }
}

enum ClipboardContent: Codable, Equatable {
    case text(String)
    case file(ClipboardFileReference)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case file
    }

    private enum ContentType: String, Codable {
        case text
        case file
    }

    var displayTitle: String {
        switch self {
        case .text(let text):
            return text
        case .file(let file):
            return file.url.lastPathComponent
        }
    }

    var detailText: String {
        switch self {
        case .text:
            return "Text"
        case .file(let file):
            return "\(file.kind.displayName) - \(file.url.deletingLastPathComponent().path)"
        }
    }

    var searchableText: String {
        switch self {
        case .text(let text):
            return text
        case .file(let file):
            return "\(file.url.lastPathComponent) \(file.url.path) \(file.kind.displayName)"
        }
    }

    var systemImageName: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .file(let file):
            return file.kind.systemImageName
        }
    }

    var mediaPreview: ClipboardMediaPreview? {
        switch self {
        case .text:
            return nil
        case .file(let file):
            switch file.kind {
            case .image:
                return .image(file.url)
            case .video:
                return .video(file.url)
            default:
                return nil
            }
        }
    }

    var revealInFinderURL: URL? {
        switch self {
        case .text:
            return nil
        case .file(let file):
            return file.url
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .file:
            self = .file(try container.decode(ClipboardFileReference.self, forKey: .file))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(text, forKey: .text)
        case .file(let file):
            try container.encode(ContentType.file, forKey: .type)
            try container.encode(file, forKey: .file)
        }
    }
}

enum ClipboardMediaPreview: Equatable {
    case image(URL)
    case video(URL)
}

struct ClipboardFileReference: Codable, Equatable {
    var url: URL
    var kind: ClipboardFileKind

    init(url: URL, kind: ClipboardFileKind? = nil, fileManager: FileManager = .default) {
        self.url = url
        self.kind = kind ?? ClipboardFileKind.classify(url: url, fileManager: fileManager)
    }
}

enum ClipboardFileKind: String, Codable, Equatable {
    case image
    case video
    case audio
    case document
    case folder
    case other

    var displayName: String {
        switch self {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        case .document:
            return "Document"
        case .folder:
            return "Folder"
        case .other:
            return "File"
        }
    }

    var systemImageName: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "film"
        case .audio:
            return "waveform"
        case .document:
            return "doc"
        case .folder:
            return "folder"
        case .other:
            return "paperclip"
        }
    }

    static func classify(url: URL, fileManager: FileManager = .default) -> ClipboardFileKind {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return .folder
        }

        switch url.pathExtension.lowercased() {
        case "apng", "avif", "bmp", "gif", "heic", "heif", "jpeg", "jpg", "png", "svg", "tif", "tiff", "webp":
            return .image
        case "avi", "m4v", "mkv", "mov", "mp4", "mpeg", "mpg", "webm":
            return .video
        case "aac", "aiff", "flac", "m4a", "mp3", "ogg", "wav":
            return .audio
        case "csv", "doc", "docx", "key", "md", "numbers", "pages", "pdf", "ppt", "pptx", "rtf", "txt", "xls", "xlsx":
            return .document
        default:
            return .other
        }
    }
}

enum ClipboardContentFilter: CaseIterable, Identifiable {
    case all
    case text
    case images
    case videos
    case files

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .text:
            return "Text"
        case .images:
            return "Images"
        case .videos:
            return "Videos"
        case .files:
            return "Files"
        }
    }

    var systemImageName: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .text:
            return "text.alignleft"
        case .images:
            return "photo"
        case .videos:
            return "film"
        case .files:
            return "doc"
        }
    }

    func matches(_ content: ClipboardContent) -> Bool {
        switch (self, content) {
        case (.all, _):
            return true
        case (.text, .text):
            return true
        case (.images, .file(let file)):
            return file.kind == .image
        case (.videos, .file(let file)):
            return file.kind == .video
        case (.files, .file(let file)):
            return file.kind != .image && file.kind != .video
        default:
            return false
        }
    }
}
