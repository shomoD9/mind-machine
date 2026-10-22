# Reusing sync engines

Pilot Point-Free's SQLiteData around encrypted CloudKit records for the Apple-first app. It can save replication work, while key management, recoverable revisions and keyboard process behavior remain application responsibilities. Keep a direct CKSyncEngine adapter as a fallback if the wrapper cannot preserve those boundaries.

Researched 22 October 2026. No sync library was installed, compiled or exercised with two devices in this pass. The existing app still has no operating encrypted sync. [Security contract and earlier source review](2026-10-22-private-sync-security.md).

## Candidate comparison

| Candidate | What can be reused | Limits for this product |
| --- | --- | --- |
| [SQLiteData](https://github.com/pointfreeco/sqlite-data/tree/37c461a814707e4b33a7d22921cafbcd43a8b125) | MIT Swift SQLite/GRDB library with a CKSyncEngine wrapper and example reminders/CloudKit applications | Best Apple-native pilot. Selected tables replicate; local indexes can stay outside sync. Schema/migrations must follow its constraints. Current main requires Swift 6.4, above our 6.2.3 toolchain. Choose a compatible release or evaluate a deliberate toolchain update. [Manifest](https://github.com/pointfreeco/sqlite-data/blob/37c461a814707e4b33a7d22921cafbcd43a8b125/Package.swift), [licence](https://github.com/pointfreeco/sqlite-data/blob/37c461a814707e4b33a7d22921cafbcd43a8b125/LICENSE). |
| [Automerge Swift](https://github.com/automerge/automerge-swift/tree/658cb91e914cabca4cba75557ed35a7de6ad1bfc) and [Repo Swift](https://github.com/automerge/automerge-repo-swift/tree/cdeb8053c3aa2510189429d717ab09e70f134716) | MIT CRDT document merging; repo adds storage/network providers | Relevant if concurrent rich-document editing needs automatic character-level merging. Repo's README says no tagged release and remaining Swift 6 incompatibilities. Transport, identities, encryption and recovery still need integration. [Repo status](https://github.com/automerge/automerge-repo-swift/blob/cdeb8053c3aa2510189429d717ab09e70f134716/README.md), [MeetingNotes example](https://github.com/automerge/MeetingNotes). |
| [PowerSync Swift](https://github.com/powersync-ja/powersync-swift/tree/c029daa4ff30d53aa8868b14b45cc715e776fcb0) | Apache-2.0 client SDK, offline SQLite and backend replication | Strong cross-platform option when we operate a backend. Requires service/database, authentication and upload connector. GRDB integration is marked alpha. Its local-encryption demo does not establish service-unreadable sync. [SDK README](https://github.com/powersync-ja/powersync-swift/blob/c029daa4ff30d53aa8868b14b45cc715e776fcb0/README.md). Current [service licence](https://github.com/powersync-ja/powersync-service/blob/e47b62068fbe9ef8a711e742593d2665d1016fb1/LICENSE) is FSL-1.1-ALv2 with a two-year future Apache grant; the whole stack cannot be described as unrestricted open source from the SDK licence alone. |
| [Electric](https://github.com/electric-sql/electric/tree/3f9809fb0bd894cb74470d434749673492ad7acf) | Apache-2.0 Postgres read-path replication through HTTP Shapes | Useful if a Postgres-backed product becomes the goal. Writes, offline upload/conflict behavior and auth still need their own design. Requires operating Postgres and the service. No verified iCloud/keyboard shortcut. [Architecture/requirements](https://github.com/electric-sql/electric/blob/3f9809fb0bd894cb74470d434749673492ad7acf/README.md). |
| [cr-sqlite](https://github.com/vlcn-io/cr-sqlite/tree/43ab94cac537d080aac7cb7628a435c02ee9e268) | MIT SQLite replication/merge extension exposing change rows | Building block for custom replication, without a complete consumer transport/key/recovery service. Static iOS packaging and our encrypted-store integration are unverified. [Change API](https://github.com/vlcn-io/cr-sqlite/blob/43ab94cac537d080aac7cb7628a435c02ee9e268/README.md). |

Pins record inspected source snapshots, rather than adoption or reliability certifications. Source availability and recent commits do not prove speed or correctness in our targets.

## SQLiteData integration gates

Its [CloudKit guide](https://github.com/pointfreeco/sqlite-data/blob/37c461a814707e4b33a7d22921cafbcd43a8b125/Sources/SQLiteData/Documentation.docc/Articles/CloudKitSync.md) describes one-column unique identifiers and distributed-schema constraints. Conflict resolution is per-column last-edit-wins and is not currently customizable. Assets use CloudKit assets. The [engine source](https://github.com/pointfreeco/sqlite-data/blob/37c461a814707e4b33a7d22921cafbcd43a8b125/Sources/SQLiteData/CloudKit/SyncEngine.swift) uses CloudKit encrypted values and requires iOS 17/macOS 14 for sync.

Application-specific consequences:

1. Preserve concurrent originals as immutable revisions or explicit conflict copies. A single encrypted mutable note field would turn a column conflict into a whole-note overwrite. Adding a wrapper does not fix this automatically.
2. Keep a local protected source/index database separate from syncable ciphertext envelopes. Commit source plus durable pending mutation atomically; ensure remote acknowledgements cannot discard unmerged revisions. Validate the wrapper's schema and event hooks against this layout.
3. Test how companion and keyboard coordinate writes, receive changes and recover after termination. Never assume a suspended companion is an always-running sync daemon. Full Access and App Groups remain necessary for the current shared-vault keyboard approach.
4. Check compatible compiler/package revisions, SQLCipher or equivalent local protection, journals, schema rollout, assets and extensions before selecting the wrapper.

These are proposed gates, not implemented architecture. If meeting them fights the library, use CKSyncEngine directly behind the same transport interface.

## iCloud and encryption

CloudKit uses the user's iCloud account through an app-managed database; there is no folder for consumers to arrange. An iCloud Drive folder can later support file export/backup, but putting a live shared database there does not provide our mutation/conflict protocol. Apple schedules background work; a sync library cannot promise a fixed background delivery deadline. [CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-4b4w9), [existing iCloud analysis](2026-10-22-private-sync-security.md#apple-platform-facts-and-their-consequences).

CloudKit encrypted fields alone do not establish our unconditional provider-unreadable promise: Apple's end-to-end protection for third-party CloudKit data depends on Advanced Data Protection. Use app-encrypted payloads and a tested device/key/recovery lifecycle for that promise. Keep sensitive search indexes local. Provider-visible identifiers, traffic and sizes still exist. [Apple's security overview](https://support.apple.com/en-us/102651).

The first executable milestone should be two vaults exchanging authenticated ciphertext, with offline writes, conflicts, account changes and deletion/no-resurrection checks through the approved seam. Then test a signed real iPhone keyboard plus Mac on actual CloudKit, measuring active-device latency separately from background convergence. There are no new sync timing measurements in this report.
