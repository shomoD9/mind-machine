# Native foundation — work in progress

This folder contains the shared domain/storage module, eight behavior tests, and an initial observable presentation model. It has no app executable, Xcode app target, installed keyboard, registered Mac hotkey, or working sync transport yet. Do not call it a launched MVP.

`SecondBrainCore` preserves original captures and explicit checklists, schedules whole-capture reminders, cancels pending reminders when a checklist completes, keeps the original time zone during edits, and records due reminders as chat events without repeating them automatically. Reopening does not restore cancelled reminders. Temporary messages do not enter retained state. `VaultFile` rereads the newest coordinated file before atomic updates.

`SecondBrainUI/VaultModel.swift` is an unconnected presentation model. It includes local search with optional system embeddings, an Ollama-compatible inference request, and system-notification requests. No UI host invokes it yet. Chat-based reminder edits, Forget, derived-memory deletion, encrypted sync, App Groups, rich-editor integration and background-delivery validation remain unimplemented. Temporary state is in memory; ending it clears that in-memory segment.

The local JSON file is not the sync format. Do not upload it as plaintext. See [native sync research](../.scratch/scattered-ambitious-pitch/research/24-native-pilot-sync-and-distribution-2026-10-20.md) before implementing encrypted replication and key provisioning.

Run the behavior tests:

```sh
swift test --package-path native --scratch-path /tmp/secondbrain-swift-build
```

The current package, including the initial presentation model, compiles on macOS and all eight domain tests pass. These checks do not validate a real keyboard, device notifications, inference quality or two-device synchronization.
