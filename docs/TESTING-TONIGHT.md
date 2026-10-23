# Test Mind Machine tonight — 23 October 2026

Build from `main` on your Mac with Xcode 26.2 or later. Linux CI verifies the Swift package and unsigned native builds on GitHub macOS runners; it cannot provision an iPhone or prove live iCloud delivery. Use a paid Apple Developer team for CloudKit, a real iPhone on iOS 17+, and a Mac on macOS 14+. Keep both devices signed into the same iCloud account with iCloud Drive and iCloud Keychain enabled.

## Preserve existing notes first

The new bundle/App Group IDs identify a new installation. Export/download the old app's container before deleting it or changing its signing. In Xcode → Window → Devices and Simulators → your iPhone → Installed Apps → old Mind Machine app → Download Container. Keep the original `.xcappdata`. Preserve the old Mac `Library/Application Support/SecondBrain` folder too. The extension's previous App Group container is a separate container; copy its `SecondBrain/vault.json` using the previously signed app before retiring that build. A newly entitled App Group cannot read the old group's sandbox.

For an existing JSON vault inside the new container, initialization creates `vault.sqlite` alongside `vault.json` in one transaction. JSON stays byte-for-byte intact. After migration SQLite is authoritative; do not edit the old JSON expecting it to import again. Keep the SQLite database together with its `-wal` and `-shm` files when exporting a running app, or quit all clients first. A malformed JSON file shows an error and is never replaced with an empty vault.

## Signing and capabilities

1. Clone/pull `shomoD9/mind-machine`. Open `native/Config/MindMachine.xcconfig` and set **only** `DEVELOPMENT_TEAM = YOUR10CHARTEAMID`. Do not commit a personal Team ID. The bundle IDs, App Group, CloudKit container and Keychain group derive from this file.
2. Open `native/MindMachine.xcodeproj`. For MindMachine, MindMachineKeyboard and MindMachineMac, select Automatic signing and that same team. Do not enter per-target bundle-ID overrides.
3. In Signing & Capabilities, ensure all three targets have App Groups `group.com.getstatemachine.mindmachine`, iCloud → CloudKit with `iCloud.com.getstatemachine.mindmachine`, and Keychain Sharing `$(AppIdentifierPrefix)com.getstatemachine.mindmachine`. Let Xcode register profiles/identifiers. If needed, create the App Group/container in developer.apple.com → Certificates, Identifiers & Profiles and associate them with each bundle identifier.
4. The identifiers must resolve to `com.getstatemachine.mindmachine`, `.keyboard`, `.mac`. Enable Push Notifications for app/Mac when provisioning the generated entitlements. The iPhone app declares Remote notifications background mode. The keyboard starts foreground requests itself and needs no companion launch for each save.
5. Select scheme **MindMachine**, your plugged-in trusted iPhone, and Run. Enable Developer Mode on the phone if requested. For Mac select scheme **MindMachineMac**, My Mac, and Run. These are signed Xcode builds; CI continues using `CODE_SIGNING_ALLOWED=NO`.
6. CloudKit uses the Development environment for these builds. The first signed save creates zone `MindMachinePrivateV1` and record type `MindMachineRevisionV1`, with encrypted field `sealedRevision`. In CloudKit Console select this container and Development. Never create a plaintext field with that same name. Production/TestFlight needs schema deployment to Production separately.

## Pair private sync once

1. Open the phone app. Under Private device sync choose **Create key on my first device**. Keep the displayed Base64 recovery key in a private password manager. This is the app encryption key; never put it in this repository or a CI secret/log.
2. Open the Mac's Capture/Find panel. Its bottom **Sync setup** button opens the same setup. If iCloud Keychain has delivered the key it says paired. Otherwise paste the phone's exact key and choose **Pair this device**. Never create another key on the second device. The app refuses replacement of a different installed key.
3. Close setup, choose **Sync now** if available, and watch the status. Local capture does not wait for sync. A wrong key or changed iCloud account pauses exchange while retaining local notes. Return to the paired account. Resetting/replacing keys or moving a resident vault to another account is deliberately unsupported in this pilot.

The note revision is AES-256-GCM encrypted by the app before entering CloudKit encrypted fields in the private database. Advanced Data Protection is optional for this additional app encryption layer. CloudKit still sees record IDs, sizes and traffic metadata. Local SQLite/FTS is protected by the app sandbox and iOS file protection, rather than a database-encryption product.

## Keyboard Capture → Find → Insert

1. Settings → General → Keyboard → Keyboards → Add New Keyboard → Mind Machine. Select it and enable **Allow Full Access**. Full Access enables the shared App Group and private-cloud networking. The app includes these instructions and a link to Settings.
2. In Notes or the included app test host, type `host draft stays here` with the normal keyboard. Switch to Mind Machine with the globe. Capture opens privately; its destination label says Private note.
3. Type `Tonight telescope code 7319` and tap Save note. Require **Saved on this device** before leaving. The host draft must remain unchanged. Force-close/reopen the host and verify the note remains in Find.
4. Choose Find. Type `teles`, then `telescpoe`. Results update while typing and bold the matching word. Open the original and choose **Insert original into app**. Only this explicit action inserts the saved text into the host. If the host proxy is unavailable, tap the app field and retry; the keyboard shows an instruction instead of writing privately.
5. Switch Capture/Find and cycle Size. Require preservation of draft, selection and destination. Type, delete, shift, punctuation and return. Test a second host app. Secure fields, phone pads and apps rejecting custom keyboards use the system keyboard.

## Verify both sync directions and offline recovery

1. Keep the Mac running and connected. Without opening the companion again, save a unique `phone 7319` note in the keyboard. Find it on Mac. Active clients request sync after save and periodically (15 seconds); allow the initial iCloud/keychain setup time. Record actual elapsed time; no fixed iOS background deadline is claimed.
2. Save `mac 8426` on Mac. Keep the phone keyboard visible, wait for its active refresh, then Find `8426`. It must return the exact original without opening the companion. If a request was in progress during save, the next active timer retries the durable queue.
3. Disable networking on both. Save distinct notes on each. Kill/relaunch both clients. Find each local note before reconnecting. Reconnect and require both originals on each device. Concurrent edits made through the shared store preserve both originals as separate result copies; tombstones prevent stale replica resurrection. The current UI has no general edit/delete workflow for ordinary notes, so those cases have deterministic fake-cloud CI coverage.
4. Sign out/change iCloud only with a backup and if you want to exercise that gate. Sync must pause, retain all local notes and avoid uploading them to the new account. Return to the original account and relaunch to resume.

## Memory, latency and remaining gates

The Release CI test uses 10k synthetic text notes, 240 warm queries including prefixes/transposed typos, and asserts query p95 below 10ms. CI also records durable append p95 and whole test-process peak RSS. The process probe kills a writer after acknowledged saves and runs two independent concurrent writers, then checks exact originals after reopening. See `verification/core-tonight-2026-10-23.md` for measured results and reproducible commands.

For **real keyboard memory**, open Find, type several queries, inspect/insert a result, then open the companion and tap **Refresh keyboard memory report**. It reports actual extension physical footprint and OS-provided remaining memory headroom with a timestamp. Repeat with your vault and while syncing. Aim for at least 15 MiB headroom under load; do not treat simulator/test-process RSS as the iPhone extension's budget. Attach Xcode → Debug → Attach to Process → MindMachineKeyboard, use the memory gauge/Instruments, and check device Analytics Data for JetsamEvent. Real-device peak memory, typing feel, cold activation and live two-device sync remain founder acceptance gates.

Lexical prefix/one-edit recall ships here. No-overlap paraphrases, image/voice ingestion and visual-semantic retrieval are unimplemented. Chat/reminders/resurfacing remain deferred. Signed-device deployment, recovery-key custody, background suspension/force-quit behavior and production CloudKit schema are separate from green unsigned CI.
