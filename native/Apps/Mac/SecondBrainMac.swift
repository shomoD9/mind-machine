/* Mac entry point and global hotkey adapter. Carbon delivers Ctrl-Option-Space
 to a native resizable panel hosting the shared WorkspaceView and local VaultModel. */
import AppKit
import Carbon
import SwiftUI
import SecondBrainUI

@main
struct SecondBrainMac: App {
    @NSApplicationDelegateAdaptor(MacDelegate.self) private var delegate
    var body: some Scene { Settings { Text("Control–Option–Space opens your vault.").padding() } }
}

@MainActor
final class MacDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let model = VaultModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Carbon registration works without monitoring general keystrokes or
        // requesting Accessibility access. Failure is shown instead of hidden.
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<MacDelegate>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in owner.togglePanel() }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let identifier = EventHotKeyID(signature: 0x5342524E, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), identifier,
                                        GetApplicationEventTarget(), 0, &hotkey)
        if status != noErr { model.error = "Global hotkey registration failed (\(status)). Open the app to access the panel." }
        showPanel()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel(); return true
    }

    func togglePanel() {
        if panel?.isVisible == true { panel?.orderOut(nil) } else { showPanel() }
    }

    private func showPanel() {
        if panel == nil {
            let window = VaultPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 580),
                                    styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                                    backing: .buffered, defer: false)
            window.title = "Second brain · Control–Option–Space"
            window.contentMinSize = NSSize(width: 380, height: 320)
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: WorkspaceView(model: model))
            window.center()
            panel = window
        }
        // Opening starts in Capture. Existing drafts remain in the shared model.
        model.activateCapture()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
    }
}

private final class VaultPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    // Escape dismisses the panel without discarding its writing session.
    override func cancelOperation(_ sender: Any?) { orderOut(sender) }
}
