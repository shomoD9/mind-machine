/* State machine for the floating pill. It decides what the pill, the panel and the menu-bar item
 should be doing after each input, and nothing else: no AppKit, no timers.
 Called by PillController (native/Apps/Mac/PillController.swift) for clicks, the global hotkey, Esc,
 click-away, tab shortcuts and the menu-bar Show/Hide item; exercised by PillStateTests. */

/// The modes a pill panel can show. `reserved` is the placeholder slot for a third mode the founder
/// will specify later; it is listed so the UI can draw a disabled tab, and the state machine refuses it.
public enum PillMode: Int, CaseIterable, Sendable {
    case capture, recall
    // PLACEHOLDER: third mode, to be specified by the founder. Keep disabled until then.
    case reserved

    public var isAvailable: Bool { self != .reserved }

    public var title: String {
        switch self {
        case .capture: return "Capture"
        case .recall: return "Recall"
        case .reserved: return "Soon"
        }
    }

    /// Index used by the shared VaultModel.mode (0 Capture, 1 Recall). The reserved slot has none.
    public var vaultModeIndex: Int? {
        switch self {
        case .capture: return 0
        case .recall: return 1
        case .reserved: return nil
        }
    }
}

public enum PillPhase: Equatable, Sendable {
    case collapsed
    case expanded(PillMode)

    public var isExpanded: Bool { if case .expanded = self { return true } else { return false } }
    public var mode: PillMode? { if case .expanded(let mode) = self { return mode } else { return nil } }
}

public enum PillEvent: Equatable, Sendable {
    case clickPill          // click on the collapsed pill
    case hotkey             // Ctrl-Option-Space: toggles
    case escape             // Esc inside the panel
    case clickAway          // panel lost key status or the user clicked another app
    case select(PillMode)   // tab click or Cmd-1 / Cmd-2
    case close              // the x button
    case toggleVisibility   // menu-bar Show/Hide pill
}

public struct PillState: Equatable, Sendable {
    /// The user's Show/Hide preference. The window is on screen when the pill is shown or the panel is open.
    public var pillShown: Bool
    public var phase: PillPhase

    public init(pillShown: Bool = true, phase: PillPhase = .collapsed) {
        self.pillShown = pillShown
        self.phase = phase
    }

    /// Whether any window should be visible at all.
    public var windowVisible: Bool { pillShown || phase.isExpanded }

    /// Applies one event. Returns what changed so the controller animates only real transitions.
    @discardableResult
    public mutating func send(_ event: PillEvent) -> PillTransition {
        let before = self
        switch event {
        case .clickPill:
            if phase == .collapsed { phase = .expanded(.capture) }
        case .hotkey:
            // Expanding always opens Capture, as the existing hotkey panel did; drafts live in the shared model.
            phase = phase.isExpanded ? .collapsed : .expanded(.capture)
        case .escape, .clickAway, .close:
            phase = .collapsed
        case .select(let mode):
            // Tabs only exist inside the panel, and the reserved slot is never selectable.
            if phase.isExpanded, mode.isAvailable { phase = .expanded(mode) }
        case .toggleVisibility:
            pillShown.toggle()
        }
        return PillTransition(before: before, after: self)
    }
}

public struct PillTransition: Equatable, Sendable {
    public let before: PillState
    public let after: PillState

    public var isNoOp: Bool { before == after }
    public var expanding: Bool { !before.phase.isExpanded && after.phase.isExpanded }
    public var collapsing: Bool { before.phase.isExpanded && !after.phase.isExpanded }
    public var modeChanged: Bool { before.phase.isExpanded && after.phase.isExpanded && before.phase != after.phase }
    public var visibilityChanged: Bool { before.windowVisible != after.windowVisible }
}
