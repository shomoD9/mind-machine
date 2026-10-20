# Native capture/refind checkpoint — 2026-10-20

Ticket 01 is resolved after the human confirmed the complete custom-keyboard capture/Find/original/Insert flow. Mac hotkey and companion capture/refind now have runtime evidence. This report records current evidence without treating compilation as launch.

## Build and tests

- Xcode 26.2 / Swift native targets: SecondBrain, SecondBrainKeyboard and SecondBrainMac compile.
- At the ticket-01 checkpoint, SwiftPM: ten tests passed at the saved-vault and public workspace boundaries.
- Test-first save/reopen/refind cycle: missing API failed compilation, then the implemented retrieval returned the exact persisted original. Unrelated search returned nothing and capture created no reminder.
- Test-first activation cycle: missing activation API failed compilation, then the shared operation returned to Capture without destroying Capture/Find/Chat drafts.
- Commands are in [native README](../../native/README.md). Build outputs/logs remain under /tmp, outside Git.
- Build warnings: no AppIntents metadata dependency, manual target-order deprecation for target-based iOS builds, and signed extension binary not stripped. No compile errors remain.

## Native runtime

The existing iPhone 15 Pro / iOS 17.5 simulator installed and launched the SDK-26.2 app. The unsigned build reported unavailable shared storage. Rebuilding with simulator ad-hoc signing registered group.dev.secondbrain.pilot, and the companion setup/test-host screen rendered without the sharing error. [Screenshot](native-companion-setup.png) shows the running app, not a design mock.

After the Mac was unlocked, its native UI saved a disposable note, displayed the persistence receipt, returned it for an incomplete-wording query and opened its original. The human confirmed the actual Control–Option–Space shortcut opens/closes the panel while another app is active. The phone companion also passed capture → Find → original through its shared container.

The embedded keyboard was initially registered in PlugInKit but absent from Settings. Restarting Settings and the simulator did not immediately expose it. Standard bundle Info version/development-region metadata was added, and a refreshed/search-filtered Settings list then showed Second brain. The individual cause is provisional; this is an observed availability result rather than a proven single-key metadata diagnosis. Apple's installed Custom Keyboard Extension template and [official keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html) were checked during diagnosis.

The keyboard is enabled and renders its private Capture workspace. Full Access was granted **only in the simulator**, after automatic approval review required and the human supplied explicit action-time permission. The companion's setup content now scrolls while a bottom safe-area inset keeps its composer immediately above the complete extension; verified in the running simulator.

The UI tool does not expose this extension's controls in its simulator AX tree and returns noWindowsAvailable for coordinate actions on its custom keys. Explicit accessibility-order instrumentation did not improve that and was removed. The human confirmed that custom-key capture → Find → original → Insert passed: the host field stayed unchanged until explicit Insert and then received the saved text. Ticket 01 is resolved. Real-phone installation/sync still need signing, account and device proof.

## Standards

Independent review required by the invoked code-review skill found stale living-design workflow status and missing operation narration, plus a duplicate-retrieval heuristic. All addressed; recheck found zero remaining actionable Standards findings for this slice.

## Spec

Independent review found keyboard reactivation could retain Find/Chat. Both native entry points now call the shared tested activateCapture operation, and the keyboard restores its visible Capture/private-note controls. Recheck found zero remaining code findings for ticket 01; the human subsequently confirmed the remaining keyboard interaction evidence.

## Release boundaries

No private cross-device sync, complete remembered-chat implementation, rich editor, pad-size controls, media extraction or natural resurfacing has been claimed. Those features retain their individual tickets and blockers. App Group sharing is device-local. Plaintext local JSON is never an acceptable sync payload. Nothing in this checkpoint means a synced pilot is launched.
