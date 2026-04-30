import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(store: ClipboardStore, settingsStore: SettingsStore) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()

        super.init()

        configureStatusItem()
        configurePopover(store: store, settingsStore: settingsStore)
    }

    func togglePopoverFromHotKey() {
        NSApp.activate(ignoringOtherApps: true)
        togglePopover(nil)
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: "ClipSpot")
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover(store: ClipboardStore, settingsStore: SettingsStore) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 470)
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ClipboardShelfMenuView(store: store, settingsStore: settingsStore) { [weak self] in
                self?.closePopover()
            }
        )
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}
