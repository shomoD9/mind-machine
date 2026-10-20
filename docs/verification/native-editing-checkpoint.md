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
