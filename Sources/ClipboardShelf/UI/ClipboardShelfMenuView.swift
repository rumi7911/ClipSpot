import AppKit
import SwiftUI

struct ClipboardShelfMenuView: View {
    private enum FocusField {
        case search
    }

    @ObservedObject var store: ClipboardStore
    @ObservedObject var settingsStore: SettingsStore
    private let onRequestClose: () -> Void
    @State private var query = ""
    @State private var copiedItemID: ClipboardItem.ID?
    @State private var freshItemID: ClipboardItem.ID?
    @State private var lastTopItemID: ClipboardItem.ID?
    @State private var isClearHovered = false
    @State private var isExitHovered = false
    @State private var isCleanupHovered = false
    @State private var isSettingsHovered = false
    @State private var keyDownMonitor: Any?
    @State private var selectedItemID: ClipboardItem.ID?
    @State private var selectedContentFilter: ClipboardContentFilter = .all
    @State private var deleteCandidate: ClipboardItem?
    @State private var showClearConfirmation = false
    @FocusState private var focusedField: FocusField?

    init(store: ClipboardStore, settingsStore: SettingsStore, onRequestClose: @escaping () -> Void = {}) {
        _store = ObservedObject(wrappedValue: store)
        _settingsStore = ObservedObject(wrappedValue: settingsStore)
        self.onRequestClose = onRequestClose
    }

    private var visibleItems: [ClipboardItem] {
        store.filteredItems(query: query, contentFilter: selectedContentFilter)
    }

    private var visibleItemIDs: [ClipboardItem.ID] {
        visibleItems.map(\.id)
    }

    var body: some View {
        ZStack {
            ClipboardShelfTheme.backgroundGradient
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(ClipboardShelfTheme.accent.opacity(0.11))
                        .frame(width: 210, height: 210)
                        .blur(radius: 34)
                        .offset(x: 42, y: -86)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.055))
                        .frame(width: 190, height: 190)
                        .blur(radius: 32)
                        .offset(x: -86, y: 72)
                }

            VStack(alignment: .leading, spacing: 14) {
                header
                controls
                filterBar
                feedback
                staleReferenceNotice
                content
                footer
                keyboardProxy
            }
            .padding(16)
        }
        .frame(width: 380, height: 470)
        .background(.ultraThinMaterial)
        .preferredColorScheme(.dark)
        .onAppear {
            lastTopItemID = store.items.first?.id
            syncSelectionWithVisibleItems()
            installKeyboardMonitor()
            focusSearch()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onMoveCommand { direction in
            handleMoveCommand(direction)
        }
        .onExitCommand {
            onRequestClose()
        }
        .onChange(of: store.items.first?.id) { _, newValue in
            guard let newValue, newValue != lastTopItemID else {
                return
            }

            lastTopItemID = newValue

            if copiedItemID == newValue {
                scheduleCopiedReset(for: newValue)
            } else {
                triggerFreshHighlight(for: newValue)
            }
        }
        .onChange(of: visibleItemIDs) { _, _ in
            syncSelectionWithVisibleItems()
        }
        .alert("Clear clipboard history?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                store.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every saved item from ClipSpot history.")
        }
        .alert(
            "Remove clipboard item?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { isPresented in
                    if isPresented == false {
                        deleteCandidate = nil
                    }
                }
            ),
            presenting: deleteCandidate
        ) { item in
            Button("Remove", role: .destructive) {
                store.removeItem(item)
                if selectedItemID == item.id {
                    selectedItemID = nil
                }
                deleteCandidate = nil
            }
            Button("Cancel", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { item in
            Text("Remove \"\(item.previewText)\" from ClipSpot history?")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("CLIPSPOT")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(ClipboardShelfTheme.accent)

                Text("Clipboard archive")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ClipboardShelfTheme.textPrimary)

                Text(historySummary)
                    .font(.caption)
                    .foregroundStyle(ClipboardShelfTheme.textSecondary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(focusedField == .search ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textTertiary)

                TextField(
                    "",
                    text: $query,
                    prompt: Text("Search or filter")
                        .foregroundStyle(ClipboardShelfTheme.textTertiary)
                )
                    .textFieldStyle(.plain)
                    .foregroundStyle(ClipboardShelfTheme.textPrimary)
                    .focused($focusedField, equals: .search)

                if query.isEmpty == false {
                    Button {
                        query = ""
                        focusSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ClipboardShelfTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        focusedField == .search
                            ? ClipboardShelfTheme.accent.opacity(0.72)
                            : ClipboardShelfTheme.panelStroke,
                        lineWidth: 1
                    )
            )

            Button {
                if settingsStore.settings.confirmBeforeClearingHistory {
                    showClearConfirmation = true
                } else {
                    store.clearHistory()
                }
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        store.items.isEmpty
                            ? ClipboardShelfTheme.textTertiary
                            : (isClearHovered ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textPrimary)
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .background(buttonBackground(isHovered: isClearHovered && store.items.isEmpty == false))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        store.items.isEmpty
                            ? ClipboardShelfTheme.panelStroke.opacity(0.5)
                            : (isClearHovered ? ClipboardShelfTheme.accent.opacity(0.7) : ClipboardShelfTheme.panelStroke),
                        lineWidth: 1
                    )
            )
            .shadow(color: isClearHovered && store.items.isEmpty == false ? ClipboardShelfTheme.accent.opacity(0.28) : .clear, radius: 14)
            .disabled(store.items.isEmpty)
            .onHover { hovering in
                isClearHovered = hovering
            }
            .animation(.easeOut(duration: 0.16), value: isClearHovered)
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let errorMessage = store.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(ClipboardShelfTheme.warning)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ClipboardShelfTheme.warning.opacity(0.32), lineWidth: 1)
                )
                .help("ClipSpot will keep listening for new text once persistence is available again.")
        }
    }

    @ViewBuilder
    private var staleReferenceNotice: some View {
        let staleCount = store.staleFileReferenceCount

        if staleCount > 0 {
            HStack(spacing: 10) {
                Label(staleReferenceMessage(for: staleCount), systemImage: "link.badge.plus")
                    .font(.caption)
                    .foregroundStyle(ClipboardShelfTheme.warning)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button {
                    store.removeStaleFileReferences()
                } label: {
                    Text("Clean up")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isCleanupHovered ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .background(buttonBackground(isHovered: isCleanupHovered))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isCleanupHovered ? ClipboardShelfTheme.accent.opacity(0.72) : ClipboardShelfTheme.warning.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: isCleanupHovered ? ClipboardShelfTheme.accent.opacity(0.24) : .clear, radius: 12)
                .onHover { hovering in
                    isCleanupHovered = hovering
                }
                .animation(.easeOut(duration: 0.16), value: isCleanupHovered)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ClipboardShelfTheme.warning.opacity(0.26), lineWidth: 1)
            )
            .help("These saved file references point to files that are no longer available on disk.")
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if store.items.isEmpty {
                emptyState(
                    title: "Archive is standing by",
                    message: "Copy plain text anywhere on your Mac and ClipSpot will start building your live archive."
                )
            } else if visibleItems.isEmpty {
                emptyState(
                    title: emptyFilterTitle,
                    message: emptyFilterMessage
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(visibleItems) { item in
                            ClipboardHistoryRow(
                                item: item,
                                isPrimary: item.id == visibleItems.first?.id,
                                isFresh: item.id == freshItemID,
                                isCopied: item.id == copiedItemID,
                                isSelected: item.id == selectedItemID,
                                showsMediaPreview: settingsStore.settings.showMediaPreviews,
                                onCopy: {
                                    selectedItemID = item.id
                                    handleCopy(item)
                                },
                                onDelete: {
                                    handleDelete(item)
                                },
                                onRevealInFinder: { url in
                                    revealInFinder(url)
                                }
                            )
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ClipboardShelfTheme.panelStroke, lineWidth: 1)
        )
    }

    private var historySummary: String {
        if store.items.isEmpty {
            return "Listening for your next useful clip"
        }

        let itemLabel = store.items.count == 1 ? "clip" : "clips"
        return "\(store.items.count) \(itemLabel) saved locally"
    }

    private func staleReferenceMessage(for count: Int) -> String {
        if count == 1 {
            return "1 media reference is missing"
        }

        return "\(count) media references are missing"
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClipboardContentFilter.allCases) { filter in
                    filterChip(for: filter)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func filterChip(for filter: ClipboardContentFilter) -> some View {
        let isSelected = selectedContentFilter == filter
        let count = count(for: filter)

        return Button {
            selectedContentFilter = filter
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImageName)
                    .font(.system(size: 11, weight: .bold))

                Text(filter.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? ClipboardShelfTheme.backgroundBottom : ClipboardShelfTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isSelected ? ClipboardShelfTheme.accent.opacity(0.82) : ClipboardShelfTheme.accent.opacity(0.12))
                    )
            }
            .foregroundStyle(isSelected ? ClipboardShelfTheme.textPrimary : ClipboardShelfTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? ClipboardShelfTheme.tileHighlightGradient : ClipboardShelfTheme.tileGradient)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? ClipboardShelfTheme.accent.opacity(0.72) : ClipboardShelfTheme.panelStroke, lineWidth: 1)
            )
            .shadow(color: isSelected ? ClipboardShelfTheme.accent.opacity(0.18) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .disabled(count == 0 && filter != .all)
        .opacity(count == 0 && filter != .all ? 0.46 : 1)
    }

    private func count(for filter: ClipboardContentFilter) -> Int {
        store.items.filter { filter.matches($0.content) }.count
    }

    private var emptyFilterTitle: String {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No \(selectedContentFilter.title.lowercased()) clips yet"
        }

        return "Nothing matches that filter"
    }

    private var emptyFilterMessage: String {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Pick another type, or copy a matching item and ClipSpot will archive it here."
        }

        return "Try a different phrase, type chip, or hit Command-F and broaden the search."
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "document.on.clipboard")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(ClipboardShelfTheme.accent)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(ClipboardShelfTheme.textPrimary)

            Text(message)
                .font(.callout)
                .foregroundStyle(ClipboardShelfTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)

            if store.items.isEmpty == false {
                Text("Command-F focuses search")
                    .font(.caption2)
                    .foregroundStyle(ClipboardShelfTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var footer: some View {
        HStack {
            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSettingsHovered ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(buttonBackground(isHovered: isSettingsHovered))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSettingsHovered ? ClipboardShelfTheme.accent.opacity(0.7) : ClipboardShelfTheme.panelStroke, lineWidth: 1)
            )
            .shadow(color: isSettingsHovered ? ClipboardShelfTheme.accent.opacity(0.28) : .clear, radius: 14)
            .onHover { hovering in
                isSettingsHovered = hovering
            }
            .animation(.easeOut(duration: 0.16), value: isSettingsHovered)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Exit ClipSpot", systemImage: "power")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isExitHovered ? ClipboardShelfTheme.accent : ClipboardShelfTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(buttonBackground(isHovered: isExitHovered))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isExitHovered ? ClipboardShelfTheme.accent.opacity(0.7) : ClipboardShelfTheme.panelStroke, lineWidth: 1)
            )
            .shadow(color: isExitHovered ? ClipboardShelfTheme.accent.opacity(0.28) : .clear, radius: 14)
            .onHover { hovering in
                isExitHovered = hovering
            }
            .animation(.easeOut(duration: 0.16), value: isExitHovered)
        }
    }

    private var keyboardProxy: some View {
        VStack {
            Button(action: focusSearch) {
                EmptyView()
            }
            .keyboardShortcut("f", modifiers: .command)

            Button(action: copySelectedItem) {
                EmptyView()
            }
            .keyboardShortcut(.return, modifiers: [])
        }
        .buttonStyle(.plain)
        .frame(width: 0, height: 0)
        .opacity(0.001)
        .accessibilityHidden(true)
    }

    private func handleCopy(_ item: ClipboardItem) {
        store.copyItem(item)
        copiedItemID = item.id
        freshItemID = nil
        scheduleCopiedReset(for: item.id)
    }

    private func handleDelete(_ item: ClipboardItem) {
        if settingsStore.settings.confirmBeforeDeletingItem {
            deleteCandidate = item
        } else {
            store.removeItem(item)
            if selectedItemID == item.id {
                selectedItemID = nil
            }
        }
    }

    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openSettings() {
        onRequestClose()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func scheduleCopiedReset(for itemID: ClipboardItem.ID) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            if copiedItemID == itemID {
                copiedItemID = nil
            }
        }
    }

    private func triggerFreshHighlight(for itemID: ClipboardItem.ID) {
        freshItemID = itemID

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            if freshItemID == itemID {
                freshItemID = nil
            }
        }
    }

    private func focusSearch() {
        focusedField = .search
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .up:
            moveSelection(by: -1)
        case .down:
            moveSelection(by: 1)
        default:
            break
        }
    }

    private func installKeyboardMonitor() {
        guard keyDownMonitor == nil else {
            return
        }

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyDown(event) ? nil : event
        }
    }

    private func removeKeyboardMonitor() {
        guard let keyDownMonitor else {
            return
        }

        NSEvent.removeMonitor(keyDownMonitor)
        self.keyDownMonitor = nil
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let action = ClipboardShelfKeyboardAction.action(
            keyCode: event.keyCode,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            modifierFlags: event.modifierFlags
        ) else {
            return false
        }

        switch action {
        case .moveUp:
            moveSelection(by: -1)
        case .moveDown:
            moveSelection(by: 1)
        case .copySelected:
            copySelectedItem()
        case .close:
            onRequestClose()
        case .focusSearch:
            focusSearch()
        }

        return true
    }

    private func moveSelection(by offset: Int) {
        guard visibleItems.isEmpty == false else {
            selectedItemID = nil
            return
        }

        let currentIndex = selectedItemID.flatMap { selectedID in
            visibleItems.firstIndex { $0.id == selectedID }
        } ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), visibleItems.count - 1)
        selectedItemID = visibleItems[nextIndex].id
    }

    private func copySelectedItem() {
        guard let selectedItemID,
              let selectedItem = visibleItems.first(where: { $0.id == selectedItemID }) else {
            return
        }

        handleCopy(selectedItem)
    }

    private func syncSelectionWithVisibleItems() {
        guard visibleItems.isEmpty == false else {
            selectedItemID = nil
            return
        }

        if let selectedItemID, visibleItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = visibleItems.first?.id
    }

    private func buttonBackground(isHovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                isHovered
                    ? ClipboardShelfTheme.tileHoverGradient
                    : LinearGradient(
                        colors: [Color.white.opacity(0.13), Color.white.opacity(0.075)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
            )
    }
}
