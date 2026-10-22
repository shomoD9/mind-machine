# Resident local vaults and sync for the keyboard MVP

Research date: 2026-10-22. This note supplements [the sync reuse survey](2026-10-22-reuse-sync-engines.md). It records source inspection and proposed experiments; no engine has passed our two-device keyboard benchmark, and no production dependency is selected here.

## Recommendation

Keep a complete usable vault and search index in application storage on each device. Sync changes between those copies. Compare **CloudKit through SQLiteData or CKSyncEngine** with **PowerSync Swift**, using the same encrypted records and the same keyboard acceptance scenarios. Start with the CloudKit branch because it matches the existing native Apple scope and avoids operating an account/database/sync service. Keep PowerSync as the managed-service alternative if CloudKit's measured behavior misses the accepted experience.

The decisive experiment is saving from the keyboard while the companion app is suspended or terminated, then finding that note on the Mac without manually opening the companion. Test the reverse direction too. A passing companion-app demo alone does not establish this behavior.

## Local copies do not require giving up iCloud

An ordinary SQLite database in the app's support directory or shared App Group container is a resident local database. CloudKit exchanges records with that database; putting the SQLite file in an iCloud Drive folder is a separate design. Apple's iCloud Drive supports downloading files and keeping them downloaded. Its storage-management behavior should not be confused with a database our app stores locally. [Apple iCloud Drive file guide](https://support.apple.com/guide/mac-help/work-with-folders-and-files-in-icloud-drive-mchl1a02d711/mac), [SQLiteData CloudKit integration](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/Documentation.docc/Articles/CloudKitSync.md).

Proposed resident behavior:

```text
Keyboard Save
    -> local durable capture + durable outgoing change
    -> local lexical index ready
    -> Saved receipt
    -> send encrypted change when network execution is available

Remote change
    -> receive + authenticate + decrypt
    -> local transaction updates vault/index
    -> Find sees the committed result
```

Search never waits for a server to return an already-local note. A freshly captured note on another device becomes searchable after that change arrives. These are two separate measurements. Full residency is a product/storage policy that needs explicit handling for attachments, local disk exhaustion, uninstall, account changes and recovery.

## Obsidian provides a reference experience, not reusable Sync source

Obsidian Sync stores a remote vault on Obsidian-operated servers, with end-to-end encryption as its default. Local vaults remain on users' devices; losing the encryption password does not erase the copies they still have locally. Its security documentation also identifies server-visible metadata and cryptographic limitations. We should borrow the consumer experience while retaining our own explicit security contract. [Obsidian Sync security](https://obsidian.md/help/sync/security).

Obsidian's release repository explicitly says the application is not open source and that it does not contain its application source. It does not provide a reusable open-source Obsidian Sync engine. A public community plugin repository is a different licensing boundary. [Obsidian release repository](https://github.com/obsidianmd/obsidian-releases/blob/master/README.md).

## Pilot A: resident SQLite plus CloudKit

### What is reusable

**SQLiteData 1.12.1**, released 2026-10-09, was inspected at tag commit `aa613accbe882b561f26e37a348a8f42e92cd398`. It is MIT licensed and builds on GRDB. The release contains `Package@swift-6.0.swift` alongside newer-toolchain manifests; our compatibility check must resolve the release using the installed Swift toolchain, rather than judge it from the newest `main` manifest. The Swift 6.0 manifest supports iOS 16/macOS 13, while CloudKit synchronization has iOS 17/macOS 14 availability. [Release](https://github.com/pointfreeco/sqlite-data/releases/tag/1.12.1), [license](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/LICENSE), [Swift 6.0 manifest](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Package%40swift-6.0.swift), [sync source](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/SyncEngine.swift).

Its adapter provides database/CloudKit mapping, change metadata, send/fetch operations and record application. Its documented merge policy is field-wise last-edit-wins. Schema evolution imposes constraints; original text, checklist completion and reminder schedule revisions need our own domain decisions. A wrapper cannot make simultaneous reminder edits or deletion races correct by itself. [Pinned synchronization guide](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/Documentation.docc/Articles/CloudKitSync.md).

### Keyboard and residency hazards found in source

- **Account changes:** the default implementation clears local data after iCloud sign-out/account switching. Implement `SyncEngineDelegate` deliberately so an account event pauses or isolates the account's vault instead of unexpectedly deleting the user's resident notes. Prevent those retained notes from automatically uploading into another person's iCloud account. [Account-change delegate](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/SyncEngineDelegate.swift).
- **Extension compatibility:** iOS initialization installs an app-lifecycle observer that invokes `UIApplication.shared.beginBackgroundTask` and `endBackgroundTask`. Compile the actual keyboard target with extension-safe APIs required before assuming this adapter can run inside it. The finding is a source-level incompatibility risk; this research did not execute that build. [Sync initialization](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/SyncEngine.swift#L280).
- **Change enrollment:** the adapter installs temporary database triggers and registers SQL functions on its database connection. A second process merely opening the shared SQLite file and writing through GRDB has not thereby proved its writes participate in synchronization. Test saves made before the companion starts, process termination, reopening, concurrent writes and replay. [Trigger definitions](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/Internal/Triggers.swift), [connection setup](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/SyncEngine.swift#L322).

If this adapter cannot satisfy the keyboard boundary, use **CKSyncEngine directly with an app-owned transactional outbox** in the same pilot. That retains Apple's synchronization machinery while requiring us to implement the database mapping, pending-change enrollment, conflict/deletion behavior and shared-process ownership. CKSyncEngine is a proprietary system API; Apple's example integration is separately MIT licensed. Its sample requires developer signing/CloudKit configuration and warns that remote-notification sync must be tested on real hardware. [Apple sample and prerequisites](https://github.com/apple/sample-cloudkit-sync-engine).

### Encryption boundary

The inspected SQLiteData code writes fields through `CKRecord.encryptedValues`. Apple documents on-device encryption for those fields, but exclusive owner/participant possession of keys is tied to Advanced Data Protection. References remain available for server use. That mechanism alone does not establish our unconditional provider-unreadable promise. [Pinned field handling](https://github.com/pointfreeco/sqlite-data/blob/1.12.1/Sources/SQLiteData/CloudKit/CloudKit%2BStructuredQueries.swift), [Apple encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues).

Our proposed boundary remains authenticated encrypted content envelopes before transport, with local protected storage and Keychain-held keys. Device enrollment, account/key recovery, rotation/revocation, deletion tombstones and replay protection still require design and tests. Opaque encrypted payloads also mean the adapter cannot merge their interior fields; use explicit independently versioned records/operations where needed. Search indexes stay local or are independently encrypted in transport; uploading plaintext search text or embeddings would contradict the promise. These are our integration responsibilities, not features demonstrated by the adapter.

## Pilot B: PowerSync Swift with a service we operate or buy

**PowerSync Swift 1.16.4** was released 2026-10-08. Its package requires Swift 6.1, supports iOS 15/macOS 12 and declares native SQLite/core dependencies. Since version 1.14 the SDK uses native Swift and its Rust core instead of wrapping Kotlin. The client is Apache-2.0. The current service uses **FSL-1.1-ALv2**, restricting competing use until its future Apache conversion; describe that server as source-available. [Pinned package](https://github.com/powersync-ja/powersync-swift/blob/1.16.4/Package.swift), [Swift SDK](https://docs.powersync.com/client-sdks/reference/swift), [client license](https://github.com/powersync-ja/powersync-swift/blob/1.16.4/LICENSE), [service license](https://github.com/powersync-ja/powersync-service/blob/main/LICENSE).

PowerSync supplies resident SQLite, a durable write-upload queue and streamed remote updates. We still provide authentication, a source database, an upload API that applies writes, conflict semantics and the deployed synchronization service or managed subscription. That is substantial reusable machinery, with more operations work than CloudKit. [Client architecture](https://docs.powersync.com/architecture/client-architecture), [backend integration](https://docs.powersync.com/configuration/app-backend/client-side-integration).

**The keyboard gate remains open.** App Group/extension support is experimental. The documentation limits connected ownership and does not support unrestricted multiple parallel writers each connecting independently. The officially safe limited scenario has a primary writing/syncing process and a secondary reader. Our keyboard writes. A lease, inter-process coordination or a separate capture inbox is an experiment requiring failure/recovery proof. Companion-only networking is insufficient if captures wait indefinitely until the user opens the app. [Multi-process constraints](https://docs.powersync.com/client-sdks/advanced/multi-process).

PowerSync documents Swift local database encryption through SQLite3MultipleCiphers, plus a ciphertext replication pattern with local decryption/query tables for E2EE. Neither automatically supplies our enrollment and recovery flow. [Encryption integration](https://docs.powersync.com/client-sdks/advanced/data-encryption). Its background-sync guide does not establish a tested Swift keyboard background solution. [Background execution evidence](https://docs.powersync.com/client-sdks/advanced/background-syncing).

## Why the other engines do not displace those two pilots

| Engine | Relevant reuse | Why it does not become the first keyboard pilot |
|---|---|---|
| Couchbase Lite Swift | Native resident database, continuous bidirectional replicator and conflict hooks; iOS source is Apache-2.0 | Central sync uses Sync Gateway and a Couchbase server. Local database encryption is an Enterprise feature; published Swift 3.1 P2P listener APIs are marked Enterprise, so current edition rights must be checked before relying on P2P. Requires a different local database/integration and a license-level decision. TLS to a server is insufficient for provider-unreadable content. [Swift replication](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html), [database encryption](https://docs.couchbase.com/couchbase-lite/current/swift/database.html), [Swift API edition markers](https://docs.couchbase.com/mobile/3.1.0/couchbase-lite-swift/Classes/URLEndpointListener.html), [source](https://github.com/couchbase/couchbase-lite-ios), [current Swift packaging](https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html) (4.x uses a separate community SPM repository). |
| Ditto | Swift SDK, local replication, nearby mesh transports | Its Swift package distributes prebuilt binaries and reserves rights. Public package metadata is not open-source engine source. Commercial evaluation would be a separate choice. [Package README](https://github.com/getditto/DittoSwiftPackage), [Swift setup](https://docs.ditto.live/sdk/latest/install-guides/swift). |
| Automerge Swift + Repo | MIT document CRDTs and pluggable network/storage; useful if concurrent rich-text collaboration becomes required | Repo's inspected release is 0.3.2 (2024-11-01). We still need transport, encrypted identities, discovery/relay, full-copy retention, durable deletion and keyboard lifecycle integration. More collaborative-editing machinery than today's immutable captures require. [Repo source](https://github.com/automerge/automerge-repo-swift), [release](https://github.com/automerge/automerge-repo-swift/releases/tag/0.3.2). |
| LiveStore | Apache-2.0 event log, SQLite materialization and synchronization | Published integrations center on JavaScript/TypeScript including Expo. No supported drop-in Swift keyboard integration was established. Embedding another runtime would need a measured case. [Repository](https://github.com/livestorejs/livestore). |
| Jazz | MIT distributed database; React Native integration | Current repository explicitly describes Jazz 2.0 alpha with an entirely new API and links Classic separately. Do not carry Classic E2EE guarantees into current code by assumption. No supported Swift keyboard client was established. [Current repository](https://github.com/garden-co/jazz), [current client setup](https://jazz.tools/docs/getting-started/client-setup). |
| Zero / Electric | Reusable server-backed distribution and reactive clients | Zero's documented native integration is TypeScript React Native/Expo; Electric describes itself as a Postgres read-path engine. Neither is a demonstrated native Swift keyboard write/replication solution. [Zero native guide](https://github.com/rocicorp/zero-docs/blob/main/contents/docs/react-native.mdx), [Electric architecture](https://github.com/electric-sql/electric/blob/main/README.md). |

## Benchmark both pilots against the same release gate

These are proposed measurements, with thresholds to be agreed before running them. No latency number below is a measured claim.

1. **Resident data:** seed 1k, 10k and 100k captures; restart offline; find old and new notes with the network blocked. Test disk pressure and account sign-out without erasing resident material. Keep large attachment transfers separate from text-record timings.
2. **Hot path:** instrument keyboard activation, local commit, lexical index commit, first visible query results, encryption, upload acknowledgement, second-device commit and second-device query visibility. Report p50/p95/p99, failures, memory and energy. Search must not wait for initial sync/bootstrap or model inference.
3. **Both directions:** keyboard capture → active Mac Find; Mac capture → already-open keyboard Find; Mac capture → cold keyboard activation. Repeat with the phone companion foreground, background, suspended, terminated by the system and explicitly force-quit. Record differences rather than average them away.
4. **Keyboard-only use:** after one-time setup, never manually open the phone companion during a capture/find session. Confirm outgoing work durably enrolls and inbound work arrives or is fetched on activation. If an ownership handoff is proposed, kill each process between lease acquisition, commit and send; verify expiration/fencing and no duplicate send/data loss. This handoff is not implemented or validated.
5. **Offline/rejoin:** simultaneous edits, reminder change versus completion, delete versus edit, duplicates, clock skew, malformed ciphertext, interrupted migration and reinstall/new-device recovery. Assert original preservation, convergence and deletion behavior independently of transport throughput.
6. **Platform constraints:** physical signed iPhone plus Mac; real push entitlements; low-power mode; restricted network; declined keyboard Full Access. Apple ties keyboard network/shared-container access to open access. Without it, preserve a clearly described offline experience; do not silently forward unrelated host typing. [Apple keyboard access boundary](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html).

A fast foreground result cannot justify promising instant delivery while iOS has suspended all eligible processes. The usable contract should distinguish immediate local capture/search, active cross-device synchronization and catch-up when a device receives execution time. The pilot must demonstrate that normal keyboard use needs no manual companion-app visit.
