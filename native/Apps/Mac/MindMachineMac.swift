/* Mac entry point. Starts the app as a menu-bar/accessory process, registers the Ctrl-Option-Space
 global hotkey through Carbon, and hands everything visible to PillController (PillController.swift):
 the floating pill that expands into the Capture / Recall panel. The menu-bar item lives in
 PillMenuBar.swift. With "--pill-selftest <file>" the app runs PillSelfTest.swift (used by native-ci)
 against a throwaway vault and exits. Debug --pill-ui-test <UUID> gives XCUITest a separate
 local vault and defaults suite. Also installs the process-lifetime reminder notification presenter. */
import AppKit
import Carbon
import MindMachinePill
import MindMachineUI

@main
enum MindMachineMacMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = MacDelegate()
        app.delegate = delegate
        // No Dock icon: the pill and the menu-bar item are the app's presence.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class MacDelegate: NSObject, NSApplicationDelegate {
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var model: VaultModel!
    private var controller: PillController!
    private var menuBar: PillMenuBar!

    func applicationDidFinishLaunching(_ notification: Notification) {
        installReminderNotificationPresentation()
        installMainMenu()

        // The self-test must never touch the person's real vault.
        let selfTestPath = Self.argument(after: "--pill-selftest")
        // XCUITest needs the running UI rather than the self-test's automatic
        // event sequence/exit. This launch path cannot be enabled in Release.
        var uiTestID: UUID?
        #if DEBUG
        uiTestID = Self.argument(after: "--pill-ui-test").flatMap(UUID.init(uuidString:))
        #endif
        if selfTestPath != nil {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("mm-selftest-\(UUID().uuidString)/vault.json")
            model = VaultModel(url: url, notificationAccess: .disabled)
        } else if let uiTestID {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("mm-ui-\(uiTestID.uuidString)/vault.json")
            model = VaultModel(url: url, notificationAccess: .disabled)
        } else {
            model = VaultModel()
        }

        // The self-test also gets its own defaults suite, so it starts from the default position and
        // leaves the person's remembered pill position alone.
        let defaults: UserDefaults
        if selfTestPath != nil {
            UserDefaults.standard.removePersistentDomain(forName: PillSelfTest.suiteName)
            defaults = UserDefaults(suiteName: PillSelfTest.suiteName) ?? .standard
        } else if let uiTestID {
            defaults = UserDefaults(suiteName: "dev.mindmachine.pill-ui-\(uiTestID.uuidString)") ?? .standard
        } else {
            defaults = .standard
        }
        controller = PillController(model: model, preferences: PillPreferences(defaults: defaults))
        menuBar = PillMenuBar(controller: controller)
        menuBar.install()
        controller.start()

        // Carbon registration works without monitoring general keystrokes or requesting Accessibility access.
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<MacDelegate>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in owner.controller.send(.hotkey) }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let identifier = EventHotKeyID(signature: 0x5342524E, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), identifier,
                                        GetApplicationEventTarget(), 0, &hotkey)
        if status != noErr { model.error = "Global hotkey registration failed (\(status)). Click the pill to open." }

        if let selfTestPath {
            PillSelfTest.run(controller: controller, hotkeyStatus: status, outputPath: selfTestPath)
        }
    }

    /// Launching the app again (Finder, Spotlight) opens the panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !controller.state.phase.isExpanded { controller.send(.hotkey) }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
    }

    private static func argument(after flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    /// An accessory app has no visible menu bar, but its main menu still routes Cmd-Q and the editing
    /// shortcuts (Cut, Copy, Paste, Select All, Undo) to the focused text view in the pill panel.
    private func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Mind Machine", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)
        NSApp.mainMenu = main
    }
}
