import SwiftUI
import AppKit

class MenuBarManager {
    private var statusItem: NSStatusItem!
    private var popover = NSPopover()

    init() {
        setupStatusBar()
        setupPopover()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "cric_info"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 280, height: 160)
        popover.behavior = .transient
        let viewModel = ScoreViewModel()

        popover.contentViewController = NSHostingController(
            rootView: ScoreView(viewModel: viewModel)
        )
    }

    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
