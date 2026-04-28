import AppKit
import SwiftUI

struct ClipboardMediaPreviewView: View {
    let preview: ClipboardMediaPreview
    let isEmphasized: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            previewContent

            mediaBadge
                .padding(4)
        }
        .frame(width: 58, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isEmphasized ? ClipboardShelfTheme.accent.opacity(0.7) : ClipboardShelfTheme.panelStroke, lineWidth: 1)
        )
        .shadow(color: isEmphasized ? ClipboardShelfTheme.accent.opacity(0.18) : .clear, radius: 10)
    }

    @ViewBuilder
    private var previewContent: some View {
        switch preview {
        case .image(let url):
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 44)
            } else {
                fallbackTile(systemImage: "photo")
            }
        case .video:
            fallbackTile(systemImage: "film")
        }
    }

    private var mediaBadge: some View {
        Text(badgeText)
            .font(.system(size: 7, weight: .black, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(ClipboardShelfTheme.backgroundBottom)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(ClipboardShelfTheme.accent)
            )
    }

    private var badgeText: String {
        switch preview {
        case .image:
            return "IMG"
        case .video:
            return "VID"
        }
    }

    private func fallbackTile(systemImage: String) -> some View {
        ZStack {
            ClipboardShelfTheme.tileGradient
            Rectangle()
                .fill(.thinMaterial)

            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isEmphasized ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textSecondary)
        }
        .frame(width: 58, height: 44)
    }
}
