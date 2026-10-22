# Reusing the Grammarly keyboard and floating-island form factors

Research date: 22 October 2026. Scope: capture and recall within the current workspace; iPhone keyboard and a persistent Mac affordance. This report proposes reuse candidates. It changes no implementation or approved ticket status.

## Recommendation

Keep our keyboard's working private-note/host routing, editor, size states and vault interface. Pilot SnipKey's typing layer for familiar touch input. For the Mac, inspect/extract EdgeNoted's small windowing module for the persistent affordance and expandable panel; evaluate ILoveNotch's floating-pill presentation as a second reference. Build our capture/recall contents against the same vault service. Arbitrary draggable placement remains work to validate: the inspected sources do not establish a finished component covering that entire requirement.

Grammarly supplies a useful interaction reference. Its keyboard is proprietary. No inspected candidate supplies our complete expandable private notepad + capture/semantic recall + encrypted sync + Mac island as a ready interchangeable client.

## Grammarly: current product and reuse boundary

Grammarly's current iPhone support describes a replacement keyboard, companion editor and Safari extension, requiring iOS 17+. Tapping its keyboard icon expands suggestion details while the user remains in the host app. The official page also describes swipe typing and emoji support. These are vendor product claims; this research did not install or runtime-test Grammarly. [Official keyboard guide](https://support.grammarly.com/hc/en-us/articles/360009187612-How-does-the-Grammarly-Keyboard-work-on-iPhones), [current App Store listing](https://apps.apple.com/us/app/grammarly-ai-keyboard-notes/id1158877342).

The service terms reserve ownership of code/interfaces and restrict copying or derivative works. Publicly available open-source dependencies do not license Grammarly's keyboard implementation for us. Use its interaction pattern as a reference; exclude its source/assets from extraction. [Current terms, sections 3.4 and 3.6](https://www.grammarly.com/terms).

## iPhone candidates

| Candidate | Evidence and maturity | Reuse decision |
| --- | --- | --- |
| **SnipKey** | Native iOS replacement keyboard; snippets, search/insertion, QWERTY and keyboard reminder features. MIT. GitHub API checked head `7797d3992da53369ee034ba1e483bdc4db859c4d`, last push 18 October 2026; 22 stars. | **Extract after a typing pilot.** Closest licensed candidate inspected for typing plus saved material. Keep our existing private editor/routing and search service. |
| **JBoard** | MIT-labelled iPhone keyboard with tap/swipe input, offline suggestions and key-target adaptation. README explicitly calls it an experimental prototype; repository showed five commits. | **Reference/benchmark.** Potential input-engine ideas, lacking a vault/notepad/recall client. Source pin and deeper code review still required. |
| **NovaKeyboardAI** | MIT; head `c0e15594d0b0cf463319a1ac123c341e74690845`, last push 13 May 2026; 11 stars. README describes adjustable keyboard size, Groq-powered rewriting/translation, and sideloading. | **Reference only.** Resizing and input separation may help; API-key setup, remote text rewriting and sideloading target do not meet our consumer capture/recall experience. |
| **ios-clipboard** | Native iOS snippet library and keyboard; head `a38964fbc6c2ac280e6766493ed275192be3fcab`, last push 27 September 2026; two stars. README states it has no license. | **Do not copy.** Useful architecture reference. Keyboard changes sync only when the companion next runs, according to its README; that does not establish fast keyboard-to-device sync. |

Sources: [SnipKey pinned tree](https://github.com/jtvargas/SnipKey/tree/7797d3992da53369ee034ba1e483bdc4db859c4d), [MIT license](https://github.com/jtvargas/SnipKey/blob/7797d3992da53369ee034ba1e483bdc4db859c4d/LICENSE); [JBoard README](https://github.com/nkrsn/jboard); [Nova pinned README](https://github.com/Son3ra1n/NovaKeyboardAI/blob/c0e15594d0b0cf463319a1ac123c341e74690845/README.md), [license](https://github.com/Son3ra1n/NovaKeyboardAI/blob/c0e15594d0b0cf463319a1ac123c341e74690845/LICENSE); [ios-clipboard pinned README including license section](https://github.com/kecoma1/ios-clipboard/blob/a38964fbc6c2ac280e6766493ed275192be3fcab/README.md).

### SnipKey extraction seam

Its key plane and callbacks provide the relevant starting point: `SnipKeyboard/QWERTY/V2/NativeKeyboardV2View.swift`, `SnipKeyboard/QWERTY/KeyboardActions.swift`, and `SnipKeyboard/QWERTY/V2/KeyboardCommitPipeline.swift`. Its callbacks also involve application-specific snippets/settings, so extraction needs an adapter. Preserve insertion/deletion/caret callbacks into our approved destination state. The prior source inspection is detailed in [keyboard/launcher reuse research](2026-10-22-keyboard-launcher-reuse.md).

Exclude its SwiftData/CloudKit storage, purchases, usage tracking and touch-event recording. The inspected `TypingTelemetry` can record row/column events when enabled. A local typing engine must not quietly inherit a separate sensitive-data collection path. Retain MIT attribution and inspect data/asset licenses independently. [Pinned architecture](https://github.com/jtvargas/SnipKey/blob/7797d3992da53369ee034ba1e483bdc4db859c4d/V2_KEYBOARD_ARCHITECTURE.md), [telemetry source](https://github.com/jtvargas/SnipKey/blob/7797d3992da53369ee034ba1e483bdc4db859c4d/SnipKeyboard/QWERTY/V2/TypingTelemetry.swift).

### Apple boundary

A custom keyboard replaces the system keyboard and draws within its input view. Its height can change. Apple documents no public mechanism here to embed the user's separately installed keyboard inside ours; adding input accessories to another app's editor requires that host app's cooperation. Our expandable notepad therefore belongs inside our own keyboard surface. Secure fields, phone-pad fields and hosts refusing keyboard extensions remain exceptions. This conclusion uses Apple's archived programming guide; verify current APIs and App Review requirements during the implementation spike. [Apple custom keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html).

## Mac candidates

### EdgeNoted: first windowing extraction candidate

**MIT, copyright 2026 The EdgeNoted Authors.** Its README describes a thin persistent edge Open Bar, a hotkey and an expandable notes/reminders panel. The repository showed 30 commits. Its Apple Notes adapter is permission-dependent and limits formatted notes; retain our own vault instead. [README](https://github.com/namuan/EdgeNoted), [license text](https://raw.githubusercontent.com/namuan/EdgeNoted/main/LICENSE).

Actual source inspection confirmed:

- `EdgePanel.swift` subclasses `NSPanel` and allows key status for editing.
- `EdgePanelController.swift` creates a borderless nonactivating panel; uses `isFloatingPanel`, `.statusBar` level, `.canJoinAllSpaces`, `.fullScreenAuxiliary` and `.stationary`; avoids hiding on deactivation; hosts SwiftUI; animates show/hide; makes the expanded panel key.
- Placement is computed from configured screen edge/size/margin. Presentation chooses the display under the pointer. This code does **not** position beside the focused text field or prove a draggable island.

[Panel source](https://raw.githubusercontent.com/namuan/EdgeNoted/main/EdgeNoted/Windowing/EdgePanel.swift), [controller source](https://raw.githubusercontent.com/namuan/EdgeNoted/main/EdgeNoted/Windowing/EdgePanelController.swift).

`OpenBarController.swift`, `HotSideMonitor.swift`, `ScreenEdge.swift` and `GlobalHotKeyController.swift` exist in the windowing directory. Open Bar code retrieval failed, so persistent-bar behavior is currently README-backed; dragging is unverified. The module requires adaptation to an anchor that the user can drag, its saved position, display reconnection/clamping and an anchored capture/recall panel. Pin a commit before copying any code. [Windowing directory](https://github.com/namuan/EdgeNoted/tree/main/EdgeNoted/Windowing).

### ILoveNotch: floating pill and expanded notes reference

MIT, copyright 2026 Niyam Vora. README describes a floating-pill option, hover/click/hotkey expansion, resizing, pinned-open state and Markdown notes. It targets macOS 14.6+. This is a broader notch utility; its fixed top/notch presentation does not establish a freely positioned anchor beside an arbitrary editor. **Reference or selective extraction** after inspecting its window/controller code and obtaining a commit pin. No runtime proof was collected. [README](https://github.com/niyamvora/ILoveNotch), [license](https://raw.githubusercontent.com/niyamvora/ILoveNotch/main/LICENSE).

### Other candidates screened

- **Isleta, MIT:** persistent island and nonactivating interaction, but macOS 26+ and top/notch placement. Reference for collapsed/expanded presentation; no notes client established. [README](https://github.com/idevtim/isleta), [license](https://raw.githubusercontent.com/idevtim/isleta/main/LICENSE).
- **tukuyomil032/Perch, Apache-2.0-labelled:** expandable persistent pill; README says beta and not yet publicly downloadable. This is a different project from the MIT `xVanTuring/Perch` notes app in the earlier survey. Broader media/usage hub. Reference; runtime/distribution maturity unproven. [Repository](https://github.com/tukuyomil032/Perch).
- **GhostLayer, MIT-labelled:** Flutter+Swift overlay with draggable Markdown notes. Different runtime and no compact capture/recall anchor established in inspected documentation. Avoid introducing Flutter for this shell. [Repository](https://github.com/HelithaSri/GhostLayer).
- **Stealth, MIT-labelled:** native draggable/resizable all-Spaces overlay, but meeting audio/remote transcription is its central workflow. Windowing reference only; exclude recording, transcription and cloud plumbing. [Repository](https://github.com/vortechron/stealth).

## Proof required before adopting code

This research includes source inspection of EdgeNoted's two panel files and the previous pinned SnipKey inspection. Other new candidates are discovery/README/license screening. None was built, installed or measured in this research. GitHub commit counts and stars describe repository size, not quality.

Pilot one small module at a time: rapid tap/rollover/delete typing and private/host destination preservation on a real iPhone; then Mac collapsed anchor, drag persistence, expansion, focus return, multiple displays, Spaces and full-screen apps. Measure activation and live recall latency using our own indexed vault. Test encrypted second-device sync separately. A similar-looking client supplies no evidence for those data or privacy guarantees.

Public API/source fetching had partial failures. An escalated network read was rejected because automatic approval review hit a usage limit, not because it determined the read unsafe. No attempted workaround of that approval was used; the report identifies the remaining source and pin gaps.
