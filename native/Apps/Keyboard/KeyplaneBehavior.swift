/* Key gestures that KeyboardKit 9.9.1 handles differently from Apple's iPhone keyboard.
 KeyboardViewController installs KeyplaneBehavior as KeyboardKit's keyboard behaviour and
 KeyplaneActionHandler as its action handler; both extend KeyboardKit's standard classes and
 change only the cases below. KeyplaneView publishes key frames into KeyplaneState and reads its
 return-key flag. The gaps they close are G4, G6, G7 and G8 in
 docs/verification/keyboard-feel-2026-10-24.md:
 - delete repeats single characters, then whole words at a slower pace (G6);
 - holding shift while tapping letters types capitals and lowercases again on release (G7);
 - touching shift or 123, sliding onto a key and lifting types that key and returns (G8);
 - return is inert while the host field is empty and asks for that (G4). */
import Foundation
import Combine
import CoreGraphics
import KeyboardKit

/// Keyplane state shared by KeyboardViewController, KeyplaneView and KeyplaneActionHandler.
final class KeyplaneState: ObservableObject {
    /// True while the host field sets enablesReturnKeyAutomatically and holds no text.
    @Published var returnKeyDisabled = false
    /// Each visible key's cell (key plus its spacing) in KeyplaneView's coordinate space.
    var keyFrames: [KeyFrame] = []
    /// When the current delete hold began; nil while delete is up.
    var deletePressDate: Date?
}

struct KeyFrame: Equatable {
    let action: KeyboardAction
    let frame: CGRect
}

/// Delete-repeat timing. KeyboardKit's gesture button deletes on touch-down, starts repeating
/// after 0.5 s and repeats every 0.1 s; these two values decide when and how fast words go.
/// Apple publishes no figures, so they are tuned by feel (see the audit, G6).
enum DeleteRepeat {
    /// Hold time after which each repeat removes a whole word (about 20 characters in).
    static let wordsAfter: TimeInterval = 2.5
    /// Minimum time between whole-word deletions: five words a second.
    static let wordInterval: TimeInterval = 0.2
}

/// KeyboardKit asks the behaviour how much one delete removes. Whole words start after
/// DeleteRepeat.wordsAfter of holding instead of KeyboardKit's 3.5 s.
final class KeyplaneBehavior: Keyboard.StandardKeyboardBehavior {
    var keyplane: KeyplaneState?

    override var backspaceRange: Keyboard.BackspaceRange {
        guard let start = keyplane?.deletePressDate else { return .character }
        return Date().timeIntervalSince(start) > DeleteRepeat.wordsAfter ? .word : .character
    }
}

/// Every key gesture passes through `handle(_:on:replaced:)`. The cases below run first and
/// either consume the gesture or fall through to KeyboardKit's standard handling.
final class KeyplaneActionHandler: KeyboardAction.StandardActionHandler {
    var keyplane: KeyplaneState?

    private var lastWordDelete = Date.distantPast
    // Shift (G7): whether shift is down, whether a letter was typed while it was, and the case to restore.
    private var shiftDown = false
    private var typedWhileShiftDown = false
    private var caseBeforeShift = Keyboard.KeyboardCase.lowercased
    // Slide (G8): the shift or layer key's cell at touch-down, the latest finger position inside
    // that cell's coordinates, and the layout to return to after a slide types a key.
    private var slideStartFrame: CGRect?
    private var slidePoint: CGPoint?
    private var slideHandled = false
    private var typeBeforeSlide = Keyboard.KeyboardType.alphabetic

    /// Called when the keyboard appears, so a gesture cut short by dismissal leaves no held shift
    /// and no touch-down capitals.
    func resetGestureState() {
        if shiftDown, !typedWhileShiftDown, keyboardContext.keyboardCase != caseBeforeShift {
            keyboardContext.keyboardCase = caseBeforeShift
        }
        shiftDown = false; typedWhileShiftDown = false
        slideStartFrame = nil; slidePoint = nil; slideHandled = false
        keyplane?.deletePressDate = nil
    }

    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction, replaced: Bool) {
        switch action {
        case .primary:
            // Apple's return key does nothing (no click, no newline) while it is shown disabled.
            if keyplane?.returnKeyDisabled == true { return }
        case .backspace:
            if !shouldDelete(on: gesture) { return }
        case .shift, .keyboardType:
            if handleModifier(gesture, on: action) { return }
        default:
            break
        }
        super.handle(gesture, on: action, replaced: replaced)
        // A letter typed while shift is held stays capital, and so does the next one (G7).
        if shiftDown, gesture == .release, caseBeforeShift != .capsLocked, action.isCharacterKey {
            typedWhileShiftDown = true
            if keyboardContext.keyboardCase != .uppercased { keyboardContext.keyboardCase = .uppercased }
        }
    }

    override func handleDrag(on action: KeyboardAction, from startLocation: CGPoint, to currentLocation: CGPoint) {
        super.handleDrag(on: action, from: startLocation, to: currentLocation)
        switch action {
        case .shift, .keyboardType: slidePoint = currentLocation
        default: break
        }
    }

    // MARK: Delete (G6)

    /// Records the hold, and lets whole-word repeats through at most every DeleteRepeat.wordInterval.
    private func shouldDelete(on gesture: Keyboard.Gesture) -> Bool {
        switch gesture {
        case .press:
            keyplane?.deletePressDate = Date()
            lastWordDelete = .distantPast
        case .release, .end:
            keyplane?.deletePressDate = nil
        case .repeatPress:
            guard behavior.backspaceRange == .word else { return true }
            let now = Date()
            if now.timeIntervalSince(lastWordDelete) < DeleteRepeat.wordInterval { return false }
            lastWordDelete = now
        default:
            break
        }
        return true
    }

    // MARK: Shift and layer keys (G7, G8)

    /// Returns true when the gesture is fully handled here.
    private func handleModifier(_ gesture: Keyboard.Gesture, on action: KeyboardAction) -> Bool {
        let isShift: Bool
        if case .shift = action { isShift = true } else { isShift = false }
        switch gesture {
        case .press:
            slideStartFrame = cellFrame(matching: action)
            slidePoint = nil
            slideHandled = false
            guard isShift else {
                typeBeforeSlide = keyboardContext.keyboardType
                return false
            }
            shiftDown = true
            typedWhileShiftDown = false
            caseBeforeShift = keyboardContext.keyboardCase
            super.handle(.press, on: action, replaced: false)
            // Capitals show on touch-down, so letters tapped while shift is held come out capital.
            if caseBeforeShift == .lowercased { keyboardContext.keyboardCase = .uppercased }
            return true
        case .release:
            if slideHandled || typeSlideTarget() { return true }
            guard isShift else { return false }
            shiftDown = false
            if typedWhileShiftDown {
                keyboardContext.keyboardCase = .lowercased
                return true
            }
            // A plain tap: undo the touch-down capitals and let KeyboardKit toggle shift and
            // detect the double tap for caps lock, exactly as before.
            if keyboardContext.keyboardCase != caseBeforeShift { keyboardContext.keyboardCase = caseBeforeShift }
            return false
        case .end:
            // Lifting far from shift or 123 sends no release, only this end.
            if !slideHandled { _ = typeSlideTarget() }
            if isShift && shiftDown {
                shiftDown = false
                if typedWhileShiftDown { keyboardContext.keyboardCase = .lowercased }
                else if !slideHandled, keyboardContext.keyboardCase != caseBeforeShift { keyboardContext.keyboardCase = caseBeforeShift }
            }
            slideStartFrame = nil
            slidePoint = nil
            return false
        default:
            return false
        }
    }

    /// When the finger lifted over a letter, symbol or space other than the pressed shift or layer key,
    /// type it as Apple's keyboard does and go back to the case or layer from before the press.
    private func typeSlideTarget() -> Bool {
        guard let start = slideStartFrame, let point = slidePoint, let frames = keyplane?.keyFrames else { return false }
        let location = CGPoint(x: start.minX + point.x, y: start.minY + point.y)
        if start.contains(location) { return false }
        guard let target = frames.first(where: { $0.frame.contains(location) })?.action, target.isSlideTarget else { return false }
        slideHandled = true
        triggerFeedback(for: .press, on: target)
        super.handle(.release, on: target, replaced: false)
        if shiftDown {
            shiftDown = false
            keyboardContext.keyboardCase = caseBeforeShift == .capsLocked ? .capsLocked : .lowercased
        } else if keyboardContext.keyboardType != typeBeforeSlide {
            keyboardContext.keyboardType = typeBeforeSlide
        }
        return true
    }

    /// The pressed key's cell. Shift and layer keys change their associated value while held
    /// (shift case, 123 becoming ABC), so they are matched by kind and position in the layout.
    private func cellFrame(matching action: KeyboardAction) -> CGRect? {
        keyplane?.keyFrames.first { frame in
            switch (frame.action, action) {
            case (.shift, .shift): return true
            case (.keyboardType, .keyboardType): return frame.action == action
            default: return false
            }
        }?.frame
    }
}

private extension KeyboardAction {
    /// Keys that type a character, including the margin strips beside a row's outer letters.
    var isCharacterKey: Bool {
        switch self {
        case .character, .characterMargin: return true
        default: return false
        }
    }

    /// Keys a slide from shift or 123 can end on: characters and the space bar.
    var isSlideTarget: Bool { isCharacterKey || self == .space }
}
