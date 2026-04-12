import SwiftUI
import AppKit
import Combine

class MenuBarManager {
    private var statusItem: NSStatusItem!
    private var popover = NSPopover()
    private let viewModel = ScoreViewModel()
    private var cancellables = Set<AnyCancellable>()

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "cric_info"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 380, height: 620)
        popover.behavior = .transient

        popover.contentViewController = NSHostingController(
            rootView: ScoreView(viewModel: viewModel)
        )
    }

    private func bindTitle() {
        viewModel.$menuBarTitle
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                self?.statusItem.button?.title = title
            }
            .store(in: &cancellables)
    }

    init() {
        setupStatusBar()
        setupPopover()
        bindTitle()
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
