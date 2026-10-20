# Keyboard focus and host layout

Research date: 20 October 2026. Official Apple documentation and installed iPhoneOS 26.2 UIKit SDK headers inspected. No app, prototype generator, host app, credentials or system settings changed. No real-device focus or layout behavior was tested.

## Finding

One custom keyboard can route its own key buttons to either the host document proxy or its private notepad state. Preserving that destination and both drafts while resizing is an application-state responsibility. **The reviewed public API does not guarantee notification of every tap in the host composer, especially a tap that leaves the same insertion point unchanged.** Therefore universal tap-host-to-return behavior remains a desired product contract requiring evidence; it is not established by the delegate callbacks.

The host app owns its composer and decides how it moves above the keyboard. A keyboard extension can change its own height but cannot enforce the host's composer constraints or scrolling behavior.

## Input destinations

Apple exposes `UIInputViewController.textDocumentProxy` for inserting/deleting host text and inspecting limited surrounding context. The extension runs in a separate process without direct access to the host text input view. [Handling text interactions](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards), [UITextDocumentProxy](https://developer.apple.com/documentation/uikit/uitextdocumentproxy).

Proposed implementation pattern, not a human-approved behavior decision:

- Maintain an explicit internal destination such as host versus private draft. When host is selected, route key events to `textDocumentProxy`; when the private notepad is selected, apply those same key events to its local draft and selection model.
- A tap on a notepad view inside the extension is observable because the extension owns that view. It can select the private destination without switching keyboards or inserting private text into the host.
- Treat the private destination as keyboard routing state. Do not assume making an embedded `UITextView` first responder preserves the remote host's responder, proxy and keyboard lifecycle. That particular UIKit arrangement requires a native test. A locally managed editable surface avoids relying on a second system keyboard, but rich selection, accessibility and IME composition then require deliberate implementation.
- Keep host context out of retained vault storage unless the human explicitly captures it. A host draft stays owned by the host; the extension should not copy/replay it when resizing.

These are deductions from the proxy boundary. Apple documents systemwide custom input and custom keyboard-owned views, but the reviewed documentation does not supply this complete two-destination notepad pattern. [Creating a custom keyboard](https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard).

## Why selection callbacks cannot prove a host tap

`UITextInputDelegate.selectionDidChange` reports a selection change; `textDidChange` reports a text change. In a custom keyboard the argument is `nil`, because it cannot directly access the host's input object. [Selection delegate contract](https://developer.apple.com/documentation/uikit/uitextinputdelegate/selectiondidchange(_:)), [keyboard delegate explanation](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards).

A changed host selection can be a useful signal that the user is working in the host composer. It does not identify the cause: a change may come from editing commands, programmatic changes, another input method, or a gesture. Conversely a tap at the existing caret may change neither text nor selection. No documented obligation requires a callback for that unchanged tap. Absence of a callback also does not establish continued private intent.

`documentIdentifier` identifies the document, not a host touch event or a fresh focus epoch. Polling context or identifiers cannot distinguish two otherwise identical states. `viewDidAppear`, height changes and generic keyboard lifecycle callbacks likewise do not document every host tap.

The SDK confirms `UIInputViewController` conforms to `UITextInputDelegate`; its public interface exposes the proxy, switching/dismissal and lexicon methods, with no generic remote-host touch callback. The delegate header defines selection/text notifications and a conversation-context change method; that additional method also does not promise arbitrary taps. This is a public-contract finding, not proof that any particular host never emits redundant callbacks.

An explicit destination control inside the extension is observable and can reliably update routing. It can serve as a fallback if the human accepts it. Whether best-effort automatic host detection is sufficient, or an explicit control is required, remains a product decision. Do not silently replace the requested tap behavior in the design.

## Internal UITextView first-responder route

A native private `UITextView` offers an alternative hypothesis to test: make it first responder when the user taps the notepad; observe its `resignFirstResponder` or `textViewDidEndEditing` when the user returns to the host. Apple documents the latter callback after the local text view closes edits and resigns. [UITextViewDelegate editing-ended contract](https://developer.apple.com/documentation/uikit/uitextviewdelegate/textviewdidendediting(_:)).

However, Apple's `becomeFirstResponder` contract is explicitly **in its window**. Success is not guaranteed; UIKit checks the current responder, and input presentation depends on a key window. [UIResponder first-responder contract](https://developer.apple.com/documentation/uikit/uiresponder/becomefirstresponder()). The keyboard/host separation documented above means the ordinary same-window guarantee cannot simply be applied across these processes. No reviewed official document states that tapping an already-active host composer must resign a text view inside a keyboard extension, nor that the extension retains its own keyplane and an immediately usable host proxy during that transition.

Therefore this route remains **plausible but unverified**, rather than disproved by the lack of a generic tap callback. Native experiment needed: demonstrate that the internal text view actually becomes first responder; that its own input-view request does not replace/reenter/dismiss the custom keyplane; and that host taps, including an unchanged-caret tap, consistently end internal editing before the next key. Observe return values, `isFirstResponder`, local begin/end callbacks, proxy identity/context availability and extension lifecycle. Test repeated transitions in several hosts on a device. A successful local `textViewDidEndEditing` event proves local editing ended; it needs accompanying host evidence to identify the destination, and cannot alone establish why it ended.

## Height and composer placement

Apple permits changing the keyboard's primary-view height through Auto Layout while the system controls width and available layout. [Configuring a custom keyboard interface](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface).

In a host app that we own, anchor the composer's bottom to the host view's `keyboardLayoutGuide.topAnchor`. Apple demonstrates that the guide follows keyboard animation and height changes. [Your guide to keyboard layout, WWDC21](https://developer.apple.com/videos/play/wwdc2021/10259/), [layout-guide sample](https://developer.apple.com/documentation/uikit/adjusting-your-layout-with-keyboard-layout-guide).

Third-party apps may use that guide, keyboard notifications, custom scroll insets, accessory views or their own layout system. The extension cannot choose their constraints. A tall extension reduces the host's usable space and may expose clipping, scrolling or size limits that differ by app/device/orientation. A FigCraft screenshot can illustrate a well-behaved host but cannot establish universal geometry. Preserve the active destination, private draft, selection and scroll state in the extension's model during height updates; do not reinitialize those values as a side effect of rebuilding its view.

## Native acceptance checks

Test several actual hosts, including same-caret tap, moved-caret tap, range selection, host field switch, dismiss/reopen, private-note tap, key repeat, deletion, marked text, rotation and every supported height. Log callback names and routing changes without logging private text. Confirm private keystrokes never enter the host and resizing never changes the destination. Test that the host composer remains usable, recording app-specific exceptions. A test host we control can establish an implementation baseline; it cannot certify other apps.

## Local SDK evidence

Read-only SDK root: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.2.sdk/System/Library/Frameworks/UIKit.framework/Headers/`.

- `UIInputViewController.h`, lines 20–38: proxy context/identifier/editing API; lines 43–69: controller public API.
- `UITextInput.h`, lines 320–330: input-delegate change callbacks.
- `UIKeyboardLayoutGuide.h`, lines 21–41: docked/undocked keyboard tracking and safe-area behavior.
- `UIResponder.h`, lines 84–92, and `UITextView.h`: ordinary responder and editing APIs; neither inspected interface declares a cross-process host-focus notification.

Apple's Markdown documentation links failed in the web fetcher; indexed official documentation and SDK headers supplied the evidence above. A shell fetch also failed DNS resolution. No secondary source was used as authority.
