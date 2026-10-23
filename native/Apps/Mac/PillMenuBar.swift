/* Menu-bar item for the pill: Show/Hide pill, Open, Quit. It also builds the right-click menu on the
 pill itself. Created by MacDelegate (MindMachineMac.swift); calls PillController.send (PillController.swift)
 and refreshes its title from the controller's state when the menu opens. */
import AppKit
import MindMachinePill

@MainActor
final class PillMenuBar: NSObject, NSMenuDelegate {
    private let controller: PillController
    private var statusItem: NSStatusItem?
    private weak var toggleItem: NSMenuItem?

    init(controller: PillController) { self.controller = controller }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Mind Machine")
                ?? NSImage(systemSymbolName: "circle.grid.2x2.fill", accessibilityDescription: "Mind Machine")
            button.image?.isTemplate = true
            button.toolTip = "Mind Machine"
        }
        item.menu = makeMenu()
        statusItem = item
        // The pill's own right-click menu offers the same actions.
        controller.root.handle.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        let open = NSMenuItem(title: "Open Mind Machine", action: #selector(open), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        let toggle = NSMenuItem(title: Self.title(pillShown: controller.state.pillShown), action: #selector(togglePill), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Mind Machine", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    private static func title(pillShown: Bool) -> String { pillShown ? "Hide pill" : "Show pill" }

    /// Titles are refreshed each time a menu opens, so they never lag behind the state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items where item.action == #selector(togglePill) {
            item.title = Self.title(pillShown: controller.state.pillShown)
        }
    }

    @objc private func open() { if !controller.state.phase.isExpanded { controller.send(.hotkey) } }
    @objc private func togglePill() { controller.send(.toggleVisibility) }
    @objc private func quit() { NSApp.terminate(nil) }
}
