# Native capture/refind checkpoint — 2026-10-20

Ticket 01 is implemented in source and remains claimed until keyboard and Mac hotkey interactions are exercised. This report records current evidence without treating compilation as launch.

## Build and tests

- Xcode 26.2 / Swift native targets: SecondBrain, SecondBrainKeyboard and SecondBrainMac compile.
- SwiftPM: ten tests pass at the saved-vault and public workspace boundaries.
- Test-first save/reopen/refind cycle: missing API failed compilation, then the implemented retrieval returned the exact persisted original. Unrelated search returned nothing and capture created no reminder.
- Test-first activation cycle: missing activation API failed compilation, then the shared operation returned to Capture without destroying Capture/Find/Chat drafts.
- Commands are in [native README](../../native/README.md). Build outputs/logs remain under /tmp, outside Git.
- Build warnings: no AppIntents metadata dependency, manual target-order deprecation for target-based iOS builds, and signed extension binary not stripped. No compile errors remain.

## Native runtime

The existing iPhone 15 Pro / iOS 17.5 simulator installed and launched the SDK-26.2 app. The unsigned build reported unavailable shared storage. Rebuilding with simulator ad-hoc signing registered group.dev.secondbrain.pilot, and the companion setup/test-host screen rendered without the sharing error. [Screenshot](native-companion-setup.png) shows the running app, not a design mock.

The Mac UI tool reported that the computer is locked and automatic unlock failed. An asynchronous unlock request is pending. Keyboard enablement, capture/find/Insert using its actual keyplane, host/private routing, and Mac hotkey interaction are not yet verified. First-ticket acceptance therefore remains open. Real-device installation still needs Apple signing setup and a phone.

## Standards

Independent review required by the invoked code-review skill found stale living-design workflow status and missing operation narration, plus a duplicate-retrieval heuristic. All addressed; recheck found zero remaining actionable Standards findings for this slice.

## Spec

Independent review found keyboard reactivation could retain Find/Chat. Both native entry points now call the shared tested activateCapture operation, and the keyboard restores its visible Capture/private-note controls. Recheck found zero remaining code findings for ticket 01; interaction evidence remains outstanding.

## Release boundaries

No private cross-device sync, complete remembered-chat implementation, rich editor, pad-size controls, media extraction or natural resurfacing has been claimed. Those features retain their individual tickets and blockers. App Group sharing is device-local. Plaintext local JSON is never an acceptable sync payload. Nothing in this checkpoint means a synced pilot is launched.
