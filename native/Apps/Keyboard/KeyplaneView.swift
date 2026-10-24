/* The KeyboardKit key area that KeyboardViewController hosts below the panel.
 KeyboardKit computes its layout (letter case, 123 and #+= layers, host keyboard type) when
 KeyboardView is created, and its own root view re-creates it on every keyboard-context change.
 This wrapper does the same by observing the context, and makes two adjustments toward Apple's
 iPhone keyboard: with no emoji keyboard, the bottom-left layer key is as wide as return, and on
 iOS 26 (Liquid Glass) the space bar carries no label. */
import SwiftUI
import KeyboardKit

struct KeyplaneView: View {
    let state: Keyboard.State
    let services: Keyboard.Services
    // Any published change (case, layer, locale, orientation, appearance) re-runs body,
    // which rebuilds KeyboardView with a freshly computed layout.
    @ObservedObject var context: KeyboardContext

    var body: some View {
        KeyboardView(
            layout: Self.appleLikeLayout(services.layoutService.keyboardLayout(for: context), context: context),
            state: state, services: services,
            buttonContent: { item in
                if item.item.action == .space && context.isLiquidGlassEnabled { Color.clear } else { item.view }
            },
            buttonView: { $0.view }, collapsedView: { $0.view },
            emojiKeyboard: { $0.view }, toolbar: { _ in EmptyView() })
            // No suggestion bar: the panel sits where Apple's predictive bar would be.
            .autocompleteToolbarStyle(.init(height: 0))
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
