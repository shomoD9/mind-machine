# Native pilot — implementation in progress

The Xcode project has three targets: `SecondBrain` (iPhone companion/test host), `SecondBrainKeyboard` (embedded custom keyboard), and `SecondBrainMac` (global-hotkey panel). Shared `SecondBrainCore` and `SecondBrainUI` libraries remain a local Swift package. The first implemented path is explicit local capture → persisted original → keyword Find → original inspection. Keyboard Insert is deliberate. This is not a launched or synced pilot.

## Build

Open `native/SecondBrain.xcodeproj`. The project, target membership, plists and schemes can be regenerated with `python3 native/Scripts/generate_project.py`. It uses no third-party project-generation dependency.

```sh
swift test --package-path native --scratch-path /tmp/secondbrain-swift-build
xcodebuild -project native/SecondBrain.xcodeproj -scheme SecondBrainMac -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/secondbrain-xcode CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/SecondBrain.xcodeproj -target SecondBrain -configuration Debug -sdk iphonesimulator ARCHS=arm64 CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- SYMROOT=/tmp/secondbrain-ios-products OBJROOT=/tmp/secondbrain-ios-intermediates build
```

All three native targets compile against the installed Xcode 26.2 SDKs. The target-based simulator command also works when Xcode cannot select a scheme destination because only the older iOS 17.5 simulator runtime is installed. The ad-hoc-signed app also installs and launches in that runtime. Its App Group is registered and the setup screen renders. This does not prove custom-keyboard interactions or real-device behavior.

Run `/tmp/secondbrain-xcode/Build/Products/Debug/SecondBrainMac.app`. Control–Option–Space opens/hides the panel; Escape dismisses it. Capture starts by default. Saved content lives under the application's local Application Support directory. The panel supports resizing.

## iPhone setup

For a real phone, select your Apple team in Xcode and register unique bundle identifiers plus a shared App Group. Set `VAULT_APP_GROUP` identically for the companion and keyboard. Current `dev.secondbrain.pilot` identifiers are development defaults. Enable the keyboard in iPhone Settings, then enable Full Access to permit access to its device-local shared vault. Full Access is an iOS permission, separate from cloud-AI opt-in. The companion includes a host message field for keyboard testing.

The keyboard refuses to create an isolated vault when the shared container is unavailable. Signed App Group availability and full phone behavior need actual device proof. Secure/password fields and hosts that prohibit custom keyboards remain platform limitations.

## Remaining work

Ticket 01 remains in progress pending keyboard interaction and Mac hotkey UI checks. Standards and Spec review found no remaining code findings in this slice. Ten package behavior tests pass; simulator companion launch and shared-container registration are verified. Native UI interaction is waiting on the locked Mac. Pad sizes, rich editing, reliable tap-to-host routing, reminder controls/delivery, searchable remembered chat/Forget, encrypted sync, media and release validation remain subsequent tickets. Chat UI calls the initial real Ollama-compatible adapter when configured; no bundled model or server is provided. Its existing model is not yet a complete remembered-chat implementation. Never infer feature completion from a control being present.

The local JSON document is plaintext device storage, **never the sync payload**. Private app-encrypted replication and account/key provisioning remain ticket 05. No CloudKit container is provisioned and no two-device sync has been verified. See [sync research](../.scratch/scattered-ambitious-pitch/research/24-native-pilot-sync-and-distribution-2026-10-20.md).

See [checkpoint evidence](../docs/verification/native-capture-checkpoint.md) for commands, results and remaining acceptance gates.
