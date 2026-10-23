# Native pilot — implementation in progress

The Xcode project has three targets: `MindMachine` (iPhone companion/test host), `MindMachineKeyboard` (embedded custom keyboard), and `MindMachineMac` (floating control). Shared core/UI libraries remain a local Swift package. Capture commits originals, the FTS5 index and a private-sync revision in SQLite before acknowledging Saved. Recall returns ranked prefix/typo matches and highlighted previews; Insert/Copy uses the original. The private CloudKit adapter compiles and has fake-cloud replication tests. Live signed-device sync and real iPhone keyboard memory/typing acceptance remain open.

Start with [TESTING-TONIGHT](../docs/TESTING-TONIGHT.md): one Team ID in `Config/MindMachine.xcconfig`, shared App Group/iCloud/Keychain capabilities, key pairing and exact device checks. CI measurements and engine selection are in [core verification](../docs/verification/core-tonight-2026-10-23.md).

## Build

Open `native/MindMachine.xcodeproj`. The project, target membership, plists and schemes can be regenerated with `python3 native/Scripts/generate_project.py`. It uses no third-party project-generation dependency.

```sh
swift test --package-path native --scratch-path /tmp/mindmachine-swift-build
xcodebuild -project native/MindMachine.xcodeproj -scheme MindMachineMac -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/mindmachine-xcode CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/MindMachine.xcodeproj -target MindMachine -configuration Debug -sdk iphonesimulator ARCHS=arm64 CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- SYMROOT=/tmp/mindmachine-ios-products OBJROOT=/tmp/mindmachine-ios-intermediates build
```

All three native targets compile against the installed Xcode 26.2 SDKs. The target-based simulator command also works when Xcode cannot select a scheme destination because only the older iOS 17.5 simulator runtime is installed. The ad-hoc-signed app also installs and launches in that runtime. Its App Group is registered and the setup screen renders. This does not prove custom-keyboard interactions or real-device behavior.

Run `/tmp/mindmachine-xcode/Build/Products/Debug/MindMachineMac.app`. Control–Option–Space opens/hides the panel; Escape dismisses it. Capture starts by default. Saved content lives under the application's local Application Support directory. The control expands from its remembered anchor; see DESIGN for the current Mac behavior.

## Continuous integration

`.github/workflows/native-ci.yml` runs on every push to `main`, every pull request and manual dispatch, only when `native/` or the workflow changes. On a GitHub-hosted `macos-26` runner with Xcode 26.2 it runs `swift test`, builds the `MindMachine` scheme (iPhone app plus embedded keyboard) for a generic iOS Simulator, and builds `MindMachineMac`, all with `CODE_SIGNING_ALLOWED=NO`. There is no signing, TestFlight or secrets. A newer run on the same ref cancels the older one. The workflow also runs the Release 10k latency budget, same-corpus FTS5/MiniSearch comparison and a SIGKILL/concurrent-writer durability probe. It does not establish real-device keyboard interaction or CloudKit signing/delivery.

## Mac development notification setup

The notification check succeeded in registering the app after signing the complete bundle and installing it in the user's Applications folder. Running the unsigned temporary build produced UNErrorDomain code 1; registering only the signed temporary bundle still failed. For local development after the build above:

```sh
codesign --force --sign - /tmp/mindmachine-xcode/Build/Products/Debug/MindMachineMac.app
mkdir -p ~/Applications
ditto /tmp/mindmachine-xcode/Build/Products/Debug/MindMachineMac.app ~/Applications/MindMachineMac.app
```

Launch the installed copy and deliberately enable device notifications in its settings. If macOS reports notifications disabled, enable MindMachineMac in System Settings → Notifications. This is local ad-hoc signing; distribution signing and real-phone installation retain their release gates.

## iPhone setup

For a real phone, set `DEVELOPMENT_TEAM` in `Config/MindMachine.xcconfig`. Bundle IDs are `com.statemachine.mindmachine` (iPhone and Mac apps share it, for universal purchase under one App Store Connect record) and `com.statemachine.mindmachine.keyboard`; App Group is `group.com.statemachine.mindmachine`, and iCloud container is `iCloud.com.statemachine.mindmachine`. All targets use the same configuration. Register capabilities with the same Apple team, then follow TESTING-TONIGHT. Enable the keyboard in iPhone Settings and enable Full Access for shared storage/networking. The companion documents this permission and provides a host message field, private-key setup and actual keyboard memory-report viewer.

The keyboard refuses to create an isolated vault when the shared container is unavailable. Signed App Group availability and full phone behavior need actual device proof. Secure/password fields and hosts that prohibit custom keyboards remain platform limitations.

## Remaining work

Ticket 01 is resolved: the human confirmed keyboard capture → Recall → original → Insert, with the host unchanged until Insert. Mac and companion UI checks passed and the real global hotkey was confirmed. Full Access was authorized only in the simulator. Real-phone proof remains a release gate.

Ticket 02 is resolved after human native acceptance, including the dormant-host-caret limitation. Ticket 03 is in progress. The keyboard now offers Min/Default/Expanded through its Size control and preserves independent mode drafts, selections, formatting and destination. Native visual editors provide Bold, Italic, Bullet and Checkbox controls, preserving RTF beside exact original text. The original reader renders matching saved RTF with a text fallback. Selected paragraphs can become a complete authored checklist; capturing alone schedules nothing. The Mac visual bold → Save → Recall → reopen path was exercised and retained its formatting. The full package suite now passes 21 tests. Human sizing, routing and formatting checks passed; the simulator tool cannot reliably target extension controls.

Checklist/reminder management is implemented in ticket 03. Native Mac controls and companion/keyboard reminder inspection passed; simulator background OS delivery was visibly verified. Mac permission and a pending OS request were verified after installing the signed app, but its visual delivery check was interrupted by computer-use service failure. Remaining keyboard checklist/date-confirm checks and real-phone proof are still open. Complete remembered chat/Forget, encrypted sync, media and release verification retain their subsequent tickets. Chat calls the preliminary configured Ollama-compatible adapter; no model/server is bundled and remembered-chat acceptance is incomplete. Never infer completion from a visible control.

The legacy JSON is retained as a migration/recovery source. SQLite is the protected local source/index; immutable revisions are AES-GCM encrypted before entering CloudKit encrypted fields. Explicit key pairing, account isolation and fake-cloud concurrent-edit/deletion behavior are implemented. A founder-signed container and real bidirectional device sync remain unverified. See TESTING-TONIGHT for those acceptance gates.

See [checkpoint evidence](../docs/verification/native-capture-checkpoint.md) for commands, results and remaining acceptance gates.

See [editing checkpoint](../docs/verification/native-editing-checkpoint.md) for ticket-02 evidence and accepted limitations. See [reminder checkpoint](../docs/verification/native-reminders-checkpoint.md) for current reminder checks.

## TestFlight delivery

`.github/workflows/testflight.yml` archives the iPhone app (with its keyboard) and the Mac app, signs them with an App Store Connect API key (repository secrets `ASC_API_KEY_P8`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `APPLE_TEAM_ID`) and uploads both to one App Store Connect record. Run it from the Actions tab (`testflight`, Run workflow) or with `gh workflow run testflight.yml`; it also runs on pushes to `main` that touch `native/`. The API key needs the Admin role so Xcode can use cloud-managed distribution certificates. `ITSAppUsesNonExemptEncryption` is `NO` because only Apple's cryptography is used. See `docs/DESIGN.md` ("TestFlight delivery") for the details and the latest run status.
