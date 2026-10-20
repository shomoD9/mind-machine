# Native editing checkpoint — 2026-10-20

Ticket 02 is claimed. Source and automated checks are ready. Human sizing and formatting checks passed; tap routing failed and keeps acceptance open.

## Implemented

- The keyboard Size control cycles Default → Expanded → Min → Default. Resizing keeps the same live editor and selected destination. Min keeps a visible note line and does not redirect typing.
- KeyboardWorkspace owns independent private Capture/Find/Chat drafts, rich text, UTF-16 selection and scroll position. Host content remains owned by the host. Send acknowledgement targets only the unchanged outgoing Chat draft and cannot erase newer writing or switch modes.
- Native UITextView/NSTextView editors offer Bold, Italic, Bullet and Checkbox. Original text and RTF persist together. Readers use matching RTF with an original-string fallback. Every selected paragraph receives an authored list prefix.
- Destination label/control is visible. Private editor begin/end and host selection callbacks are connected; actual tap behavior, including unchanged host carets, still needs proof.

## Verification

The full package suite passed **16 tests**, including new failing-first cycles for workspace sizing, independent mode selections, send acknowledgement, rich persistence, visual checkbox capture and native selected-paragraph editing through save/reopen. Tests cross the approved workspace and saved-vault interfaces; no private collaborators were mocked.

Xcode 26.2 builds the Mac app, iPhone companion and embedded keyboard. In the Mac UI, selected “shelf” was made bold, saved, found and reopened with bold retained. In the simulator, the default keyboard size, formatting toolbar, destination label and host composer above the complete workspace were visually inspected.

The simulator UI tool still omits extension controls from its AX tree and returns noWindowsAvailable for coordinate actions on them. The installed build is ready for a human check of:

1. Draft/selection preservation through Expanded → Min → Default, typing into the collapsed note and composer visibility.
2. Tap host field / tap private pad routing, including a tap at the existing host caret.
3. Keyboard Bold → Save → Find → original preserving formatting.

Human results: **all sizing checks passed**, **formatting passed**, and **tap routing failed**. The failing direction and caret condition are being isolated before changing focus logic. A state test or screenshot cannot substitute for this native failure. The human already confirmed the earlier ticket-01 capture/Find/Insert flow and real Mac hotkey.

## Review

Standards and Spec reviews ran separately against the approved c319917 baseline, including pending/new files. Fixed stale status, duplicated draft ownership and the plain original reader. Follow-up reviews reported zero remaining code findings. Keep this ticket open until the native interaction checks above are observed.

## Limits

Current private writing sessions live in memory; saved captures are durable. Exact Apple keyboard behavior, universal host tap callbacks and true iPhone fullscreen are unproven. Size requests remain subject to iOS/host constraints. This checkpoint does not complete reminders, remembered chat, media, private cross-device sync or release verification.
