/* Key-press sound and haptics for the KeyboardKit keyplane. KeyboardViewController installs
 InputClickFeedbackService as KeyboardKit's feedback service. Sound goes through
 UIDevice.playInputClick, which plays only when the person has Keyboard Clicks turned on in
 iOS Settings (Sounds & Haptics → Keyboard Feedback → Sound). Haptics use KeyboardKit's own
 engine (UIFeedbackGenerator), which iOS silences when System Haptics is off. iOS does not
 expose the separate Keyboard Feedback → Haptic switch to third-party keyboards. */
import UIKit
import KeyboardKit

final class InputClickFeedbackService: FeedbackService {
    private let haptics = Feedback.StandardFeedbackService()

    func triggerAudioFeedback(_ feedback: Feedback.Audio) {
        // Apple's keyboard has distinct delete/modifier clicks; the public API offers one click,
        // and it is the only route that follows the system Keyboard Clicks setting.
        if case .none = feedback { return }
        UIDevice.current.playInputClick()
    }

    func triggerHapticFeedback(_ feedback: Feedback.Haptic) {
        haptics.triggerHapticFeedback(feedback)
    }
}

// playInputClick sounds only while a visible input view opts in. The extension's root view is
// the system-created UIInputView, so the opt-in is declared on that class (this process only).
extension UIInputView: @retroactive UIInputViewAudioFeedback {
    public var enableInputClicksWhenVisible: Bool { true }
}
