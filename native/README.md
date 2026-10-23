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

## Continuous integration

`.github/workflows/native-ci.yml` runs on every push to `main`, every pull request and manual dispatch, only when `native/` or the workflow changes. On a GitHub-hosted `macos-26` runner with Xcode 26.2 it runs `swift test`, builds the `SecondBrain` scheme (iPhone app plus embedded keyboard) for a generic iOS Simulator, and builds `SecondBrainMac`, all with `CODE_SIGNING_ALLOWED=NO`. There is no signing, TestFlight or secrets. A newer run on the same ref cancels the older one. The workflow compiles and runs unit tests only; it does not exercise keyboard interaction or real-device behavior.

## Mac development notification setup

The notification check succeeded in registering the app after signing the complete bundle and installing it in the user's Applications folder. Running the unsigned temporary build produced UNErrorDomain code 1; registering only the signed temporary bundle still failed. For local development after the build above:

```sh
codesign --force --sign - /tmp/secondbrain-xcode/Build/Products/Debug/SecondBrainMac.app
mkdir -p ~/Applications
ditto /tmp/secondbrain-xcode/Build/Products/Debug/SecondBrainMac.app ~/Applications/SecondBrainMac.app
```

Launch the installed copy and deliberately enable device notifications in its settings. If macOS reports notifications disabled, enable SecondBrainMac in System Settings → Notifications. This is local ad-hoc signing; distribution signing and real-phone installation retain their release gates.

## iPhone setup

For a real phone, select your Apple team in Xcode and register unique bundle identifiers plus a shared App Group. Set `VAULT_APP_GROUP` identically for the companion and keyboard. Current `dev.secondbrain.pilot` identifiers are development defaults. Generated bundle metadata includes its Info dictionary version and development region; confirm actual keyboard availability in Settings after installation, since PlugInKit registration alone is insufficient. Enable the keyboard in iPhone Settings, then enable Full Access to permit access to its device-local shared vault. Full Access is an iOS permission, separate from cloud-AI opt-in. The companion includes a host message field for keyboard testing.

The keyboard refuses to create an isolated vault when the shared container is unavailable. Signed App Group availability and full phone behavior need actual device proof. Secure/password fields and hosts that prohibit custom keyboards remain platform limitations.

## Remaining work

Ticket 01 is resolved: the human confirmed keyboard capture → Find → original → Insert, with the host unchanged until Insert. Mac and companion UI checks passed and the real global hotkey was confirmed. Full Access was authorized only in the simulator. Real-phone proof remains a release gate.

Ticket 02 is resolved after human native acceptance, including the dormant-host-caret limitation. Ticket 03 is in progress. The keyboard now offers Min/Default/Expanded through its Size control and preserves independent mode drafts, selections, formatting and destination. Native visual editors provide Bold, Italic, Bullet and Checkbox controls, preserving RTF beside exact original text. The original reader renders matching saved RTF with a text fallback. Selected paragraphs can become a complete authored checklist; capturing alone schedules nothing. The Mac visual bold → Save → Find → reopen path was exercised and retained its formatting. The full package suite now passes 21 tests. Human sizing, routing and formatting checks passed; the simulator tool cannot reliably target extension controls.

Checklist/reminder management is implemented in ticket 03. Native Mac controls and companion/keyboard reminder inspection passed; simulator background OS delivery was visibly verified. Mac permission and a pending OS request were verified after installing the signed app, but its visual delivery check was interrupted by computer-use service failure. Remaining keyboard checklist/date-confirm checks and real-phone proof are still open. Complete remembered chat/Forget, encrypted sync, media and release verification retain their subsequent tickets. Chat calls the preliminary configured Ollama-compatible adapter; no model/server is bundled and remembered-chat acceptance is incomplete. Never infer completion from a visible control.

The local JSON document is plaintext device storage, **never the sync payload**. Private app-encrypted replication and account/key provisioning remain ticket 05. No CloudKit container is provisioned and no two-device sync has been verified. See [sync research](../.scratch/scattered-ambitious-pitch/research/24-native-pilot-sync-and-distribution-2026-10-20.md).

See [checkpoint evidence](../docs/verification/native-capture-checkpoint.md) for commands, results and remaining acceptance gates.

See [editing checkpoint](../docs/verification/native-editing-checkpoint.md) for ticket-02 evidence and accepted limitations. See [reminder checkpoint](../docs/verification/native-reminders-checkpoint.md) for current reminder checks.
