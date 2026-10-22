# Reusing keyboard and hotkey clients

SnipKey is the closest reviewed open-source iPhone keyboard candidate for typing plus saved snippets/search/insertion. Noty and Maccy supply useful native Mac interaction code. None of the reviewed projects has been verified to deliver the entire Capture/Find/remembered-Chat pad, reminders, private sync and near-field Mac launcher together.

Research checked 22 October 2026. No client code was copied, built or integrated during this pass. Preserve the working app while testing small extracted modules. The [earlier detailed client report](2026-10-22-keyboard-launcher-reuse.md) contains source paths, licences and Apple constraints for SnipKey, Maccy, KeyboardShortcuts and RustCast.

## Candidates that can save work

| Project | Relevant source | Proposed use |
| --- | --- | --- |
| [SnipKey](https://github.com/jtvargas/SnipKey/tree/7797d3992da53369ee034ba1e483bdc4db859c4d) | MIT iOS custom keyboard, QWERTY plane and snippet search/insertion | First typing-engine pilot. Adapt key insertion/deletion/caret callbacks into our workspace. Search UI/storage and product actions are coupled to SnipKey, so this is selective extraction. Exclude its optional key-position telemetry, purchases and unrelated storage. [Key plane](https://github.com/jtvargas/SnipKey/blob/7797d3992da53369ee034ba1e483bdc4db859c4d/SnipKeyboard/QWERTY/V2/NativeKeyboardV2View.swift). |
| [Noty](https://github.com/aimen08/noty/tree/2a1a81dee03de5d5d7903fbf2cea16ce9c9cec3d) | MIT Swift macOS capture application with hotkey, search and tasks | Closest reviewed Mac note-capture reference. Inspect selected panel/search interactions behind our vault interface. No iPhone keyboard or proof of our semantic/private-sync contract. |
| [Maccy](https://github.com/p0deje/Maccy/tree/c700182f638d9d29bfa0aec9dc560422698854c6) | MIT Swift hotkey popup, filtering and selection/paste | Reuse/reference panel navigation and activation behavior. Avoid introducing its clipboard-history collection. |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts/tree/772133d9dbe800fdac0473226822994c5c162c58) | MIT native configurable global shortcuts | Small package if users need shortcut customization. Existing Carbon hotkey already works; replacing it alone changes no retrieval latency. |
| [Perch](https://github.com/xVanTuring/Perch/tree/a54af5ed4b24aa4ac756072a15c4fe82af261487) | MIT Mac notes/hotkey/Markdown application | Secondary editor/panel reference. Its Mac 15 minimum exceeds our Mac 14 minimum; selective reuse needs availability checks. Do not import selected-text or clipboard capture implicitly. [Licence](https://github.com/xVanTuring/Perch/blob/a54af5ed4b24aa4ac756072a15c4fe82af261487/LICENSE). |

Activity dates and exact source pins for the first four are recorded in the earlier report and prior component survey. They establish inspected versions, without guaranteeing maintenance, speed or security. Every selected extraction needs attribution, dependencies/assets reviewed and an upstream update strategy.

## Additional keyboard leads and exclusions

[Jev Jarvis](https://github.com/jev-chat/jev-chat-jarvis-ios) publishes an MIT iOS keyboard that displays reply candidates and inserts a chosen reply. Its [English README](https://github.com/jev-chat/jev-chat-jarvis-ios/blob/master/README.en.md) puts full QWERTY and a contact/standing-note knowledge base on the roadmap, describes a fixed-height panel and requires user-supplied model configuration. Useful setup/insertion patterns; it does not supply our retained vault/search or complete typing engine. Broad compatibility/privacy statements in that README were not independently validated. [Licence](https://github.com/jev-chat/jev-chat-jarvis-ios/blob/master/LICENSE).

[Diction](https://github.com/DictionLabs/Diction) initially looks like an open-source keyboard candidate. Its [README](https://github.com/DictionLabs/Diction/blob/main/README.md) explicitly identifies this public repository as the **Go voice gateway** for its iOS app. The gateway's MIT licence does not establish availability of the keyboard client source. It may inform future voice transport, but it is excluded from the reusable key-plane shortlist. No encryption/privacy claim from its marketing was treated as an audit result. [Licence](https://github.com/DictionLabs/Diction/blob/main/LICENSE).

The earlier report also checks KeyboardKit: its current SDK is a closed binary, despite a public repository. RustCast's README says it is retired. FlorisBoard is Android code; Raycast's open-source extensions require the Raycast host. These boundaries prevent misleading reuse estimates.

## What remains ours

Keep the accepted rich notepad, Capture/Find/Chat modes, sizing/drafts, host/private routing, explicit Insert and reminder behavior. Test any replacement key plane for rapid typing, rollover, delete repeat, selection, hardware input and language support in an actual extension. Source resemblance alone cannot establish Apple-keyboard parity.

The Mac panel can be a small AppKit adapter around the shared retrieval interface. On the hotkey, optional Accessibility geometry can locate the focused field/caret; missing permission or unsupported geometry falls back to a predictable screen position. Read only geometry/range, avoid collecting host text, and bound cross-process waiting. No reviewed launcher guarantees placement beside every app's caret. [Apple geometry/permission evidence](2026-10-22-keyboard-launcher-reuse.md#mac-panel-near-the-text-field).

Reuse can reduce typing, panel and shortcut work. Our cross-surface state, source-preserving retrieval, consumer assistant, privacy/key lifecycle and replication acceptance still require integration and tests.
