/* Owns the floating pill: the state machine (MindMachinePill.PillState), the single non-activating
 window, the expand/collapse animation, drag-to-move with remembered position, click-away handling,
 display/Space/wake re-placement and the link between the pill's Capture/Find tabs and the shared
 VaultModel.mode. Created by MacDelegate (MindMachineMac.swift); driven by the pill handle, the
 Ctrl-Option-Space hotkey, Esc, tab shortcuts (PillPanel.swift) and the menu-bar item (PillMenuBar.swift);
 timed and inspected by PillSelfTest.swift in CI.

 Design notes: one window animates between pill size and panel size, with the content laid out once at
 final size (PillRootView). The pill is never key, so clicking it cannot steal focus; the panel becomes
 key without activating the app, so the app underneath stays active and gets keyboard focus back when the
 panel collapses. Multi-display placement and drag follow Wisp's IslandController (MIT); see
 THIRD_PARTY_NOTICES.md. */
import AppKit
import Combine
import QuartzCore
import MindMachinePill
import MindMachineUI

@MainActor
final class PillController: NSObject, NSWindowDelegate {
    private(set) var state: PillState
    /// Menu-bar item and any other observer learns about every real state change here.
    var onStateChange: ((PillState) -> Void)?
    /// Called when an expand or collapse animation finishes, with the seconds since the triggering event.
    /// Used by PillSelfTest to measure responsiveness.
    var onSettled: ((PillTransition, TimeInterval) -> Void)?
    /// Test hook: forces Reduce Motion on or off; nil follows the system setting.
    var reduceMotionOverride: Bool?

    let model: VaultModel
    let panel: PillPanel
    let root: PillRootView
    let viewModel = PillViewModel()
    private let preferences: PillPreferences
    private let screensProvider: @MainActor () -> [PillScreen]

    /// Where the pill rests (also where it is while the panel is open: the origin of the animation).
    private(set) var pillFrame: NSRect
    private var expansion: PillExpansion?
    /// Final frame of the open panel, used as the collapse reference while an animation is in flight.
    private var expandedTarget: NSRect?
    private var animating = false
    /// Incremented per animation so a superseded animation's completion does nothing.
    private var generation = 0
    private var clickAwayMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []

    init(model: VaultModel,
         preferences: PillPreferences = PillPreferences(),
         screens: @escaping @MainActor () -> [PillScreen] = PillController.currentScreens) {
        self.model = model
        self.preferences = preferences
        self.screensProvider = screens
        self.state = PillState(pillShown: preferences.pillShown)
        pillFrame = PillGeometry.resolvePillFrame(storedCenter: preferences.center, screens: screens())
        panel = PillPanel(frame: pillFrame)
        root = PillRootView(viewModel: viewModel, model: model)
        super.init()

        panel.contentView = root
        panel.delegate = self
        panel.onEscape = { [weak self] in self?.send(.escape) }
        panel.onSelectModeShortcut = { [weak self] index in
            self?.send(.select(index == 0 ? .capture : .find))
        }
        viewModel.onSelect = { [weak self] mode in self?.send(.select(mode)) }
        viewModel.onClose = { [weak self] in self?.send(.close) }

        root.handle.onClick = { [weak self] in self?.send(.clickPill) }
        root.handle.onMove = { [weak self] origin in self?.movePill(toOrigin: origin) }
        root.handle.onDragEnded = { [weak self] in self?.finishPillDrag() }
    }

    // MARK: Lifecycle

    /// Shows the pill (unless the user hid it) and starts watching displays, Spaces and wake.
    func start() {
        applyWindowVisibility()
        prewarmContent()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        })
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didWakeNotification] {
            observers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.reassertWindow() }
            })
        }
        // Tabs inside the shared view (for example "Back to Find") change VaultModel.mode directly;
        // mirror that into the state machine. Our own writes come back as no-ops.
        model.$mode.dropFirst().removeDuplicates().sink { [weak self] index in
            guard let self, let mode = PillMode.allCases.first(where: { $0.vaultModeIndex == index }) else { return }
            self.send(.select(mode))
        }.store(in: &cancellables)
    }

    /// Builds the SwiftUI panel once, invisibly, so the first expansion does not pay for creating it
    /// (the first click measured about 90 ms slower than later ones without this).
    private func prewarmContent() {
        root.content.isHidden = false
        root.layoutSubtreeIfNeeded()
        root.content.displayIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.state.phase.isExpanded else { return }
            self.root.content.isHidden = true
        }
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0); NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
        removeClickAwayMonitor()
        panel.orderOut(nil)
    }

    // MARK: Events

    func send(_ event: PillEvent) {
        let startedAt = CACurrentMediaTime()
        let transition = state.send(event)
        guard !transition.isNoOp else { return }
        if event == .toggleVisibility { preferences.pillShown = state.pillShown }
        if transition.expanding { expand(transition, startedAt: startedAt) }
        else if transition.collapsing { collapse(transition, startedAt: startedAt) }
        else if transition.modeChanged { switchMode() }
        else if transition.visibilityChanged { applyWindowVisibility() }
        onStateChange?(state)
    }

    var reduceMotion: Bool { reduceMotionOverride ?? NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    // MARK: Expand / collapse

    private func expand(_ transition: PillTransition, startedAt: CFTimeInterval) {
        let screens = screensProvider()
        // A display change may have happened while the pill was hidden; place from the stored position.
        if !panel.isVisible { pillFrame = PillGeometry.resolvePillFrame(storedCenter: preferences.center, screens: screens) }
        let opening = PillGeometry.expansion(from: pillFrame, screens: screens)
        expansion = opening
        expandedTarget = opening.panelFrame

        // Opening always starts in Capture; all drafts stay in the shared model.
        viewModel.mode = .capture
        viewModel.reduceMotion = reduceMotion
        model.activateCapture()

        panel.allowsKey = true
        panel.isMovableByWindowBackground = true
        root.handle.isHidden = true
        root.content.isHidden = false
        if !panel.isVisible {
            panel.setFrame(pillFrame, display: false)
            root.setExpandedAppearance(false, animated: false)
        }
        panel.makeKeyAndOrderFront(nil)
        installClickAwayMonitor()
        animate(to: opening.panelFrame, base: PillMotion.expand, expanded: true) { [weak self] in
            guard let self else { return }
            self.onSettled?(transition, CACurrentMediaTime() - startedAt)
        }
        focusEditor(for: .capture)
    }

    private func collapse(_ transition: PillTransition, startedAt: CFTimeInterval) {
        removeClickAwayMonitor()
        let screens = screensProvider()
        // While the open animation is still running the live frame is mid-flight; use its destination.
        let reference = animating ? (expandedTarget ?? panel.frame) : panel.frame
        let target = expansion.map { PillGeometry.collapsedFrame(panelFrame: reference, pillOffset: $0.pillOffset, screens: screens) } ?? pillFrame
        if target != pillFrame { preferences.center = CGPoint(x: target.midX, y: target.midY) }
        pillFrame = target
        panel.isMovableByWindowBackground = false
        root.handle.isHidden = false
        animate(to: target, base: PillMotion.collapse, expanded: false) { [weak self] in
            guard let self else { return }
            // Give up key status for good: closing and re-showing hands keyboard focus back to the app below.
            self.panel.allowsKey = false
            self.root.content.isHidden = true
            if self.panel.isKeyWindow { self.panel.orderOut(nil) }
            self.applyWindowVisibility()
            self.onSettled?(transition, CACurrentMediaTime() - startedAt)
        }
    }

    private func animate(to frame: NSRect, base: TimeInterval, expanded: Bool, completion: @escaping () -> Void) {
        generation += 1
        let token = generation
        let duration = PillMotion.duration(base, reduceMotion: reduceMotion)
        animating = duration > 0
        let finish = { [weak self] in
            guard let self, token == self.generation else { return }
            self.animating = false
            self.panel.invalidateShadow()
            completion()
        }
        guard duration > 0 else {
            panel.setFrame(frame, display: true)
            root.setExpandedAppearance(expanded, animated: false)
            finish()
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            // Fast start, soft landing.
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
            root.setExpandedAppearance(expanded, animated: true)
        }, completionHandler: {
            MainActor.assumeIsolated { finish() }
        })
    }

    private func switchMode() {
        guard let mode = state.phase.mode else { return }
        viewModel.mode = mode
        if let index = mode.vaultModeIndex, model.mode != index { model.mode = index }
        focusEditor(for: mode)
    }

    // MARK: Focus

    /// Puts the caret in the mode's input (note editor for Capture, query field for Find) as soon as
    /// SwiftUI has built it, retrying briefly because the view swap lands a tick after the mode change.
    func focusEditor(for mode: PillMode, attempt: Int = 0) {
        guard state.phase == .expanded(mode) else { return }
        if let target = PillFocus.editor(for: mode, in: root.content) {
            if !holdsFocus(target) { panel.makeFirstResponder(target) }
        } else if attempt < 8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in self?.focusEditor(for: mode, attempt: attempt + 1) }
        }
    }

    /// A text field being edited is not the first responder itself; its shared field editor is.
    func holdsFocus(_ target: NSView) -> Bool {
        if panel.firstResponder === target { return true }
        if let editor = panel.firstResponder as? NSTextView, editor.isFieldEditor, editor.delegate === target { return true }
        return false
    }

    // MARK: Click away

    func windowDidResignKey(_ notification: Notification) {
        guard state.phase.isExpanded else { return }
        // A popover or menu owned by this app (a date picker, say) may take key status briefly; that is not a click away.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.state.phase.isExpanded else { return }
            if let key = NSApp.keyWindow, key !== self.panel { return }
            if self.panel.isKeyWindow { return }
            self.send(.clickAway)
        }
    }

    private func installClickAwayMonitor() {
        guard clickAwayMonitor == nil else { return }
        // Mouse-down events delivered to other apps. This needs no Accessibility permission.
        clickAwayMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.send(.clickAway) }
        }
    }

    private func removeClickAwayMonitor() {
        if let clickAwayMonitor { NSEvent.removeMonitor(clickAwayMonitor) }
        clickAwayMonitor = nil
    }

    // MARK: Drag

    private func movePill(toOrigin origin: CGPoint) {
        let proposed = NSRect(origin: origin, size: PillGeometry.pillSize)
        let clamped = PillGeometry.clampPill(proposed, screens: screensProvider())
        panel.setFrameOrigin(clamped.origin)
        pillFrame = clamped
    }

    private func finishPillDrag() {
        pillFrame = panel.frame
        preferences.center = CGPoint(x: pillFrame.midX, y: pillFrame.midY)
        panel.invalidateShadow()
    }

    // MARK: Visibility and displays

    func applyWindowVisibility() {
        if state.windowVisible {
            if !state.phase.isExpanded {
                panel.setFrame(pillFrame, display: true)
                root.setExpandedAppearance(false, animated: false)
                root.content.isHidden = true
            }
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    private func screensChanged() {
        let screens = screensProvider()
        if state.phase.isExpanded {
            // Keep the open panel on a connected display.
            panel.setFrame(PillGeometry.clamp(panel.frame, in: PillGeometry.screen(for: panel.frame, in: screens)?.visibleFrame ?? panel.frame), display: true)
        } else {
            // Re-resolve from the stored position, so a pill that fell back when a monitor was unplugged
            // returns to its remembered spot when the monitor comes back.
            pillFrame = PillGeometry.resolvePillFrame(storedCenter: preferences.center, screens: screens)
            if state.windowVisible { panel.setFrame(pillFrame, display: true) }
        }
    }

    /// Space switches and wake from sleep can drop a floating window; bring it back without taking focus.
    private func reassertWindow() {
        if state.windowVisible { panel.orderFrontRegardless() }
    }

    static func currentScreens() -> [PillScreen] {
        NSScreen.screens.map { screen in
            let number = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            return PillScreen(id: number, frame: screen.frame, visibleFrame: screen.visibleFrame)
        }
    }
}

/// Finds the input that should receive the caret in each mode by walking the hosted SwiftUI view tree.
@MainActor
enum PillFocus {
    static func editor(for mode: PillMode, in view: NSView) -> NSView? {
        switch mode {
        case .capture: return first(in: view) { ($0 as? NSTextView).map { $0.isEditable && $0.isFieldEditor == false } ?? false }
        case .find: return first(in: view) { ($0 as? NSTextField).map { $0.isEditable && $0.isEnabled } ?? false }
        case .reserved: return nil
        }
    }

    private static func first(in view: NSView, where match: (NSView) -> Bool) -> NSView? {
        if !view.isHiddenOrHasHiddenAncestor, match(view) { return view }
        for sub in view.subviews { if let found = first(in: sub, where: match) { return found } }
        return nil
    }
}
