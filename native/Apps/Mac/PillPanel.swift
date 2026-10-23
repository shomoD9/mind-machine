/* The borderless, non-activating NSPanel that hosts both the collapsed pill and the expanded panel.
 One window changes size, so expanding and collapsing never swap windows (no flicker). It is created
 and driven by PillController (PillController.swift).

 Window recipe lifted and adapted from HuggingChat for macOS FloatingPanel.swift
 (https://github.com/huggingface/chat-macOS, commit 7d13a41, Apache-2.0, Copyright 2022 Hugging Face SAS):
 non-activating panel, floating, joins all Spaces, full-screen auxiliary, keyboard-capable, clear
 background. Changes: borderless instead of titled, status-bar level, key status only while expanded,
 Esc and Cmd-shortcut handling added. Collection behaviour and level follow Wisp's IslandController
 (MIT). See THIRD_PARTY_NOTICES.md. */
import AppKit
import MindMachinePill

final class PillPanel: NSPanel {
    /// The collapsed pill never takes key status, so clicking it cannot pull focus from the app underneath.
    var allowsKey = false
    var onEscape: () -> Void = {}
    var onSelectModeShortcut: (Int) -> Void = { _ in }

    init(frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        // Above ordinary and floating windows, below the screen saver; the same level Wisp's island uses.
        level = .statusBar
        // On every Space, over full-screen apps, outside Mission Control and Cmd-Tab cycling.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .none
        // The panel is dragged by its own handle when collapsed and by its background when expanded.
        isMovable = true
        isMovableByWindowBackground = false
        // Keep working while the app is not active, which is always the case here.
        worksWhenModal = true
    }

    override var canBecomeKey: Bool { allowsKey }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        // Esc closes the panel unless an input method is composing text.
        if event.type == .keyDown, event.keyCode == 53, allowsKey,
           !((firstResponder as? NSTextView)?.hasMarkedText() ?? false) {
            onEscape()
            return
        }
        super.sendEvent(event)
    }

    override func cancelOperation(_ sender: Any?) { onEscape() }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard allowsKey, event.type == .keyDown else { return super.performKeyEquivalent(with: event) }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command, let key = event.charactersIgnoringModifiers {
            switch key {
            case "1": onSelectModeShortcut(0); return true
            case "2": onSelectModeShortcut(1); return true
            default: break
            }
        }
        if super.performKeyEquivalent(with: event) { return true }
        // Edit shortcuts work even when the main menu does not claim them (the app is never active).
        guard flags == .command, let key = event.charactersIgnoringModifiers else { return false }
        let action: Selector?
        switch key {
        case "x": action = #selector(NSText.cut(_:))
        case "c": action = #selector(NSText.copy(_:))
        case "v": action = #selector(NSText.paste(_:))
        case "a": action = #selector(NSText.selectAll(_:))
        case "z": action = Selector(("undo:"))
        default: action = nil
        }
        guard let action else { return false }
        return NSApp.sendAction(action, to: nil, from: self)
    }
}

/// Transparent view over the collapsed pill. It tells a click from a drag (PillDrag, in
/// MindMachinePill) and reports the result to the controller.
final class PillHandleView: NSView {
    var onClick: () -> Void = {}
    var onMove: (CGPoint) -> Void = { _ in }
    var onDragEnded: () -> Void = {}
    /// Overridable so the CI self-test can drive a drag without a real pointer.
    var mouseLocation: () -> CGPoint = { NSEvent.mouseLocation }
    private var drag: PillDrag?

    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    // The window is movable only through this handle, never by AppKit's background dragging.
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        drag = PillDrag(startMouse: mouseLocation(), windowOrigin: window.frame.origin)
    }

    override func mouseDragged(with event: NSEvent) {
        // Optional chaining mutates the stored struct in place and yields nil while still a click.
        if let origin = drag?.update(mouse: mouseLocation()) { onMove(origin) }
    }

    override func mouseUp(with event: NSEvent) {
        defer { drag = nil }
        guard let state = drag else { return }
        if state.isDragging { onDragEnded() } else { onClick() }
    }

    // VoiceOver and keyboard access: the pill is a button.
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
    override func accessibilityLabel() -> String? { "Open Mind Machine" }
    override func accessibilityPerformPress() -> Bool { onClick(); return true }
}
