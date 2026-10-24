/* The KeyboardKit key area that KeyboardViewController hosts below the panel.
 KeyboardKit computes its layout (letter case, 123 and #+= layers, host keyboard type) when
 KeyboardView is created, and its own root view re-creates it on every keyboard-context change.
 This wrapper does the same by observing the context, and adjusts KeyboardKit toward Apple's
 iPhone keyboard: on iOS 26 (Liquid Glass) key heights, gaps and screen margins follow Apple's
 measured geometry (AppleGeometry below); with no emoji keyboard, the bottom-left layer key is as
 wide as return; on iOS 26 the space bar carries no label; letter keys offer Apple's long-press
 alternates (KeyAlternates.swift); an action return key (Go, Search, Send…) takes the panel's
 prominent grey instead of blue, and greys out while KeyplaneState says it is disabled. It also
 publishes each key's cell into KeyplaneState for KeyplaneActionHandler's slide-to-type.
 Stable key identifiers let KeyboardAcceptanceTests and KeyboardFeelTests tap the same
 gesture-backed keys people use. Gaps and evidence: docs/verification/keyboard-feel-2026-10-24.md. */
import SwiftUI
import KeyboardKit
import MindMachineUI

struct KeyplaneView: View {
    let state: Keyboard.State
    let services: Keyboard.Services
    // Any published change (case, layer, locale, orientation, appearance) re-runs body,
    // which rebuilds KeyboardView with a freshly computed layout.
    @ObservedObject var context: KeyboardContext
    // The return-key flag re-runs body too; key frames are written without publishing.
    @ObservedObject var keyplane: KeyplaneState

    /// The coordinate space key frames are measured in.
    static let space = "mind-machine-keyplane"

    var body: some View {
        KeyboardView(
            layout: Self.appleLikeLayout(services.layoutService.keyboardLayout(for: context), context: context),
            state: state, services: services,
            buttonContent: { item in
                if item.item.action == .space && context.isLiquidGlassEnabled { Color.clear } else { item.view }
            },
            buttonView: { item in
                item.view.accessibilityIdentifier(Self.keyIdentifier(item.item.action))
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: KeyFramesKey.self,
                                               value: [KeyFrame(action: item.item.action, frame: geo.frame(in: .named(Self.space)))])
                    })
            }, collapsedView: { $0.view },
            emojiKeyboard: { $0.view }, toolbar: { _ in EmptyView() })
            // No suggestion bar: the panel sits where Apple's predictive bar would be.
            .autocompleteToolbarStyle(.init(height: 0))
            .keyboardButtonStyle(builder: { params in
                Self.buttonStyle(params, context: context, returnKeyDisabled: keyplane.returnKeyDisabled)
            })
            .keyboardCalloutActions { params in
                KeyAlternates.actions(for: params.action) { params.standardActions(for: context) }
            }
            .coordinateSpace(name: Self.space)
            .onPreferenceChange(KeyFramesKey.self) { [keyplane] frames in keyplane.keyFrames = frames }
            // Apple's outer key faces sit 7.33 pt from the screen edge; KeyboardKit's sit 4 pt in.
            .padding(.horizontal, AppleGeometry.applies(to: context) ? AppleGeometry.edgePadding : 0)
    }

    /// KeyboardKit's style for every key, except the return key: Apple paints an action return
    /// (Go, Search, Send, Done…) blue; here it takes the prominent grey used by Save note. While
    /// disabled it looks like a plain return key with a faint label, as on Apple's keyboard.
    static func buttonStyle(_ params: Keyboard.ButtonStyleBuilderParams, context: KeyboardContext,
                            returnKeyDisabled: Bool) -> Keyboard.ButtonStyle {
        var style = params.standardStyle(for: context)
        guard case .primary(let type) = params.action else { return style }
        if returnKeyDisabled {
            style = KeyboardAction.primary(.return).standardButtonStyle(for: context, isPressed: false)
            style.foregroundColor = Greyscale.inkTertiary.color
        } else if !type.isSystemAction {
            let fill = Greyscale.prominent.color
            style.backgroundColor = params.isPressed ? fill.opacity(0.8) : fill
            style.foregroundColor = Greyscale.onProminent.color
        }
        return style
    }

    // Character IDs survive automatic case changes; layer IDs describe the target
    // layout. Return and space stay identifiable even when their labels are hidden.
    static func keyIdentifier(_ action: KeyboardAction) -> String {
        switch action {
        case .character(let text): return "keyboard-key-\(text.lowercased())"
        case .shift: return "keyboard-key-shift"
        case .backspace: return "keyboard-key-delete"
        case .space: return "keyboard-key-space"
        case .primary: return "keyboard-key-return"
        case .keyboardType(.numeric): return "keyboard-key-123"
        case .keyboardType(.alphabetic): return "keyboard-key-abc"
        default: return "keyboard-key-\(action.accessibilityLabel ?? "other")"
        }
    }

    /// KeyboardKit's free core has no emoji keyboard, so its view drops the emoji key and gives
    /// the space to the space bar. Apple's keyboard without an emoji key widens the layer key
    /// (123 / ABC) to the width of return instead. Rows with a globe key are left unchanged.
    static func appleLikeLayout(_ layout: KeyboardLayout, context: KeyboardContext) -> KeyboardLayout {
        guard context.deviceTypeForKeyboard == .phone, var bottom = layout.itemRows.last else { return layout }
        bottom.removeAll { $0.action == .keyboardType(.emojis) }
        guard !bottom.contains(where: { $0.action == .nextKeyboard }),
              let primary = bottom.first(where: { if case .primary = $0.action { return true } else { return false } }),
              let first = bottom.first, case .keyboardType = first.action else { return layout }
        bottom[0].size.width = primary.size.width
        var adjusted = layout
        adjusted.itemRows[adjusted.itemRows.count - 1] = bottom
        return adjusted
    }
}

/// Collects every key cell's frame from the current layout; stale layers never linger because
/// preferences come only from views on screen.
private struct KeyFramesKey: PreferenceKey {
    static let defaultValue: [KeyFrame] = []
    static func reduce(value: inout [KeyFrame], nextValue: () -> [KeyFrame]) {
        value.append(contentsOf: nextValue())
    }
}

/// Apple's iOS 26 iPhone key geometry, measured from CI screenshots of Apple's keyboard and this
/// one on the same simulators (audit G1). KeyboardKit reads its device-configuration presets for
/// both key layout and callout placement, so the presets are replaced once, before any layout.
/// KeyboardKit draws a key face 1 pt inside its inset on each side, hence the 2.67 pt inset for
/// Apple's 7.33 pt gap. Before iOS 26 KeyboardKit's own presets already match Apple's older keyboard.
enum AppleGeometry {
    /// Added around the keyplane so the outer faces sit 7.33 pt from the screen edge (3.67 + 2.67 + 1).
    static let edgePadding: CGFloat = 3.67
    static let horizontalInset: CGFloat = 2.67

    static func applies(to context: KeyboardContext) -> Bool {
        context.isLiquidGlassEnabled && context.deviceTypeForKeyboard == .phone
    }

    /// Called by KeyboardViewController.configureKeyboardKit when Liquid Glass is on.
    static func install() {
        typealias Config = KeyboardLayout.DeviceConfiguration
        let landscape = Config(buttonCornerRadius: 9,
                               buttonInsets: EdgeInsets(top: 4, leading: horizontalInset, bottom: 4, trailing: horizontalInset),
                               rowHeight: 35.33)
        // Phones narrower than 428 pt: KeyboardKit adds 2 pt to the row and takes 0.5 pt from each
        // vertical inset on iOS 26 portrait, giving Apple's 54 pt row and 43 pt key face.
        Config.standardPhone = Config(buttonCornerRadius: 9,
                                      buttonInsets: EdgeInsets(top: 6, leading: horizontalInset, bottom: 6, trailing: horizontalInset),
                                      rowHeight: 52)
        // Pro Max and Plus: 56 pt rows with 45 pt faces, no KeyboardKit adjustment.
        Config.standardPhoneLarge = Config(buttonCornerRadius: 9,
                                           buttonInsets: EdgeInsets(top: 5.5, leading: horizontalInset, bottom: 5.5, trailing: horizontalInset),
                                           rowHeight: 56)
        // Landscape: 35.33 pt rows with 27.33 pt faces on every phone.
        Config.standardPhoneLandscape = landscape
        Config.standardPhoneLargeLandscape = landscape
    }
}
