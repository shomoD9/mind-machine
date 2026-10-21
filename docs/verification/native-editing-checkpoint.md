# Native editing checkpoint — 2026-10-20

Ticket 02 is claimed. Source and automated checks are ready. Human sizing and formatting checks passed. The reported tap failure was reproduced and corrected for basic hardware input in the simulator test host; on-screen-key and broader native acceptance remain open.

## Implemented

- The keyboard Size control cycles Default → Expanded → Min → Default. Resizing keeps the same live editor and selected destination. Min keeps a visible note line and does not redirect typing.
- KeyboardWorkspace owns independent private Capture/Find/Chat drafts, rich text, UTF-16 selection and scroll position. Host content remains owned by the host. Send acknowledgement targets only the unchanged outgoing Chat draft and cannot erase newer writing or switch modes.
- Native UITextView/NSTextView editors offer Bold, Italic, Bullet and Checkbox. Original text and RTF persist together. Readers use matching RTF with an original-string fallback. Every selected paragraph receives an authored list prefix.
- Destination label/control is visible. The controller records the private proxy document after editing begins and observes context callbacks for a return to a host document. It retains the host proxy, routes basic hardware insertion/deletion as well as custom keys, and hides the private caret while App is selected. A simultaneous note tap selects the private route without blocking native selection. The local responder stays active to keep the extension visible. App writes require a nonprivate proxy and fail visibly if unavailable.

## Verification

The full package suite passed **16 tests**, including new failing-first cycles for workspace sizing, independent mode selections, send acknowledgement, rich persistence, visual checkbox capture and native selected-paragraph editing through save/reopen. Tests cross the approved workspace and saved-vault interfaces; no private collaborators were mocked.

Xcode 26.2 builds the Mac app, iPhone companion and embedded keyboard. In the Mac UI, selected “shelf” was made bold, saved, found and reopened with bold retained. In the simulator, the default keyboard size, formatting toolbar, destination label and host composer above the complete workspace were visually inspected.

The simulator UI tool still omits extension controls from its AX tree and returns noWindowsAvailable for coordinate actions on them. The installed build is ready for a human check of:

1. Draft/selection preservation through Expanded → Min → Default, typing into the collapsed note and composer visibility.
2. Tap host field / tap private pad routing, including a tap at the existing host caret.
3. Keyboard Bold → Save → Find → original preserving formatting.

Human results: **all sizing checks passed**, **formatting passed**, and **tap routing failed**. The failure was isolated to private-note → host taps with both carets active. See the regression evidence below. A state test or screenshot cannot substitute for this native failure. The human already confirmed the earlier ticket-01 capture/Find/Insert flow and real Mac hotkey.

## Review

Standards and Spec reviews ran separately against the approved c319917 baseline, including pending/new files. Fixed stale status, duplicated draft ownership and the plain original reader. Follow-up reviews reported zero remaining code findings. Keep this ticket open until the native interaction checks above are observed.

## Limits

Current private writing sessions live in memory; saved captures are durable. Exact Apple keyboard behavior, universal host tap callbacks and true iPhone fullscreen are unproven. Size requests remain subject to iOS/host constraints. This checkpoint does not complete reminders, remembered chat, media, private cross-device sync or release verification.

## Routing regression — 20 October 2026

Minimal failing sequence: tap private note, type `n`, tap the host at its existing caret, type `h`. Before the fix the private note became `nh` and the host stayed empty. CUA reproduced the same failure with a disposable letter. No portable workspace-state test can exercise UIKit's cross-process responder/proxy handoff, so no simulated callback unit test is presented as regression proof.

Temporary, content-free native logs showed no private editing-ended or host selection callback. `textDidChange` did arrive. Private activation also emitted that callback, including one after `becomeFirstResponder` returned, so blindly selecting App on every callback was rejected. Window key state stayed true throughout. A proxy lookup during view construction stalled activation and was removed; the identity query works after context delivery. At that point the proxy document changed on private activation and returned to the host document on host tap. Resigning the private responder then switched to Apple's keyboard, so that candidate was rejected.

With the keyboard-preserving fix, native UI showed note `n`, host `h`, then note `np` after tapping back and typing `p`; host remained `h`. Label followed each tap and the private caret was hidden during App routing. These observations use basic Mac hardware keystrokes in the iOS 17.5 simulator's representative host, not an assurance about every host, physical iPhone, IME, hardware navigation or clipboard operation. On-screen key actions remain unreliable through CUA and require the human check. Temporary diagnostics are removed from source. Both review axes caught a missing-cache fallback that could address the private proxy; it was replaced by one validated host-proxy path shared by insertion, deletion and Insert original, with a visible unavailable-host message.

Final source (diagnostics removed and host validation applied) compiled and repeated the native sequence successfully. Host deletion removed only the host letter; tapping back and typing appended only to the private note. Follow-up Standards and Spec reviews reported zero remaining code findings. The installed final build is awaiting the single on-screen-key confirmation; ticket 02 remains claimed.

## Human acceptance and caret follow-up — 21 October 2026

The human confirmed the final on-screen-letter-key sequence passes: note → host → note, with correct labels and the extension staying open. They also clarified the earlier failing replay had used on-screen keys. This establishes custom-key routing in the simulator test host in addition to the earlier hardware-input regression.

The human reported both cursors blinking. CUA reproduced both visible insertion carets while the label selected Private note. Tapping the host field changed the label to App and hid the private caret. The remaining host caret is drawn by the other app. The public UITextDocumentProxy interface exposes text/context/position operations, with no host caret-visibility or styling control. This is a finding from the installed iOS 26.2 SDK header and [Apple's proxy documentation](https://developer.apple.com/documentation/uikit/uitextdocumentproxy), not a claim that every possible responder architecture has been exhausted. The earlier resign-local experiment replaced this extension with Apple's keyboard and is not a usable fix. No host text, selection or responder was modified to disguise the caret.

A clarification is pending about whether the human also sees the private caret during App routing. That would be a separate local rendering defect, since the keyboard owns that caret. Ticket 02 remains claimed during this final visual follow-up; routing itself is confirmed. No native source or device settings were changed during this follow-up.

## Private caret and menu candidate — 21 October 2026

The human clarified that both carets blink during App routing too, and supplied a screenshot of both native edit menus. This corrects any inference that immediate local-caret hiding in the earlier CUA sample established a persistent fix. CUA reproduced both menus and dual carets during Private routing; an App snapshot hid the local caret immediately, so the reported delayed/intermittent App recurrence is not yet agent-reproduced.

The candidate gates `caretRect` and `selectionRects` on the explicit destination, retaining the real selection positions. It also updates public selection-display interactions and dismisses owned edit-menu interactions for App. A private tap does not request a collapsed-caret menu; a simultaneous hold marks deliberate menu intent, and selected text retains the native menu. No private UIKit hierarchy is searched or changed. Host caret/menu handling is outside the extension's reviewed public API; the companion was not changed to mask that boundary.

The iPhone/keyboard targets compile with Xcode 26.2 and the candidate is installed. CUA again returned `noWindowsAvailable` for custom-keyboard coordinate actions, followed by a user-changed-app signal, so simple-tap/hold behavior and persistent App caret absence still require native acceptance. A workspace state unit test cannot prove UIKit rendering/gesture behavior; no artificial callback test was added. Ticket 02 stays claimed. Earlier 16 passing package tests concern unchanged domain/workspace behavior.

Both independent code-review axes and a final idempotent-selection-refresh recheck reported zero findings. The final source rebuilt and was reinstalled. A single grouped human native check is pending for App caret absence, ordinary private tap menus, deliberate hold/range menus and continued routing. This is a reviewed candidate, not a verified visual resolution.

## Candidate failed acceptance; isolate spelling behavior — 21 October 2026

The latest human report does not accept the interaction: initial dual carets, host caret during Private note, and single-tap word selection/replacement popups. App selection hides the private caret in this latest report. Two screenshots show native word selections and “No Replacements Found”. Treat the earlier passing routing sequence as narrow input evidence only, not acceptance of the complete focus/selection contract.

CUA switched the host to Apple's keyboard and activated the host field. Word selection and a Copy/Replace menu also appeared there. This isolates that observed AX-activation behavior from our extension, but does not establish that a human single click behaves identically. The host source is an ordinary SwiftUI TextField with no tap/select-all handler. A human baseline with correctly spelled “hello world” is pending; the simulator is left on Apple's keyboard so that test remains valid.

[Apple's spelling-trait documentation](https://developer.apple.com/documentation/uikit/uitextinputtraits/spellcheckingtype) describes correction suggestions when tapping misspelled words. That makes spelling replacement a testable explanation for the screenshots, rather than proof of a custom tap-gesture failure. Removed the unsuccessful custom hold/menu gate and built a candidate with native spell checking/autocorrection disabled only in the private editor. Native selection/copy/paste remain enabled; host settings/source remain untouched. Build succeeded; this candidate has not been installed or manually accepted. No further proxy, responder or caret workaround was introduced. Single-caret behavior across arbitrary hosts remains an unsupported requirement in the current architecture.

Independent Standards and Spec reviews of the spelling-isolation candidate returned zero code findings. Both explicitly retain the incomplete focus/selection acceptance; no install or native pass is inferred from review.
