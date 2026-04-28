import SwiftUI

struct ClipboardHistoryRow: View {
    let item: ClipboardItem
    let isPrimary: Bool
    let isFresh: Bool
    let isCopied: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onRevealInFinder: ((URL) -> Void)?
    @State private var isHovered = false
    @State private var isRevealHovered = false

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isPrimary ? ClipboardShelfTheme.accent : ClipboardShelfTheme.accentMuted)
                .frame(width: 4)
                .padding(.vertical, 8)
                .padding(.leading, 8)

            Button(action: onCopy) {
                rowContent
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            revealButton
                .padding(.trailing, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tileFill)
        )
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeOut(duration: 0.16), value: isHovered)
        .animation(.easeOut(duration: 0.16), value: isRevealHovered)
        .animation(.easeOut(duration: 0.20), value: isCopied)
        .animation(.easeOut(duration: 0.20), value: isFresh)
        .help(item.text)
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            leadingVisual

            VStack(alignment: .leading, spacing: 6) {
                Text(item.previewText.isEmpty ? "Untitled clipboard item" : item.previewText)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(ClipboardShelfTheme.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text(item.detailText)
                        .font(.caption)
                        .foregroundStyle(ClipboardShelfTheme.textTertiary)
                        .lineLimit(1)

                    Text(ClipboardShelfRelativeTimeFormatter.string(from: item.capturedAt))
                        .font(.caption)
                        .foregroundStyle(ClipboardShelfTheme.textSecondary)

                    statusBadge
                }
            }

            Image(systemName: isCopied ? "checkmark.circle.fill" : "arrow.up.left")
                .font(.system(size: isCopied ? 13 : 12, weight: .bold))
                .foregroundStyle(
                    isCopied
                        ? ClipboardShelfTheme.accent
                        : (isHovered || isFresh || isSelected ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textTertiary)
                )
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isCopied {
            Text("COPIED")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(ClipboardShelfTheme.accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(ClipboardShelfTheme.accent.opacity(0.14))
                )
        } else if isFresh {
            Text("NEW")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(ClipboardShelfTheme.textPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(ClipboardShelfTheme.panelStroke.opacity(0.5))
                )
        }
    }

    @ViewBuilder
    private var revealButton: some View {
        if let revealURL = item.content.revealInFinderURL,
           let onRevealInFinder {
            Button {
                onRevealInFinder(revealURL)
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isRevealHovered ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(isRevealHovered ? ClipboardShelfTheme.tileHoverGradient : ClipboardShelfTheme.tileGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(isRevealHovered ? ClipboardShelfTheme.accent.opacity(0.7) : ClipboardShelfTheme.panelStroke, lineWidth: 1)
                    )
                    .shadow(color: isRevealHovered ? ClipboardShelfTheme.accent.opacity(0.22) : .clear, radius: 10)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isRevealHovered = hovering
            }
            .help("Reveal in Finder")
        }
    }

    private var tileFill: LinearGradient {
        if isCopied || isFresh || isSelected {
            return ClipboardShelfTheme.tileHighlightGradient
        }

        return isHovered ? ClipboardShelfTheme.tileHoverGradient : ClipboardShelfTheme.tileGradient
    }

    private var borderColor: Color {
        if isCopied || isFresh || isSelected {
            return ClipboardShelfTheme.accent.opacity(0.65)
        }

        return isHovered ? ClipboardShelfTheme.accent.opacity(0.55) : ClipboardShelfTheme.panelStroke
    }

    @ViewBuilder
    private var leadingVisual: some View {
        if let mediaPreview = item.content.mediaPreview {
            ClipboardMediaPreviewView(
                preview: mediaPreview,
                isEmphasized: isCopied || isFresh || isHovered || isSelected
            )
        } else {
            Image(systemName: item.content.systemImageName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isCopied || isFresh || isHovered || isSelected ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textSecondary)
                .frame(width: 18)
                .padding(.top, 1)
        }
    }
}
