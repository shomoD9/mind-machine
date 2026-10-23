# Private sync and security research

Research date: 22 October 2026, Asia/Kolkata. This report uses current first-party documentation and source inspection. It proposes engineering requirements; it does not certify the app, select an audited encryption protocol, or claim implemented sync. No credentials, permissions, accounts or production data were changed.

## Recommendation

Keep capture and search local. Replicate small, authenticated, app-encrypted records asynchronously. The server should receive ciphertext and the minimum routing metadata needed to sync. Use Apple's maintained cryptographic and account APIs behind replaceable adapters. Measure the complete keyboard-to-second-device path before promising latency. Rust is optional implementation machinery; encryption, correct conflict handling and background execution constraints remain regardless of language.

The existing privacy decision is stronger than ordinary cloud storage encryption: the service must be unable to read contents, and cloud AI is separately opt-in. That contract is recorded in [ADR 0001](../adr/0001-private-sync-and-optional-cloud-ai.md). The proposed module boundaries below implement that contract; they are recommendations for review.

## Current repository evidence

Inspected `native/Sources`, target entitlements, package manifest, ticket 05, README and the earlier [sync report](../../.scratch/scattered-ambitious-pitch/research/24-native-pilot-sync-and-distribution-2026-10-20.md).

- [VaultFile.swift](../../native/Sources/MindMachineCore/VaultFile.swift) reads and atomically rewrites a coordinated JSON document. It performs no application encryption and sets no explicit file-protection class. Plaintext here means the application format; it does not mean that the operating system lacks disk encryption.
- [Package.swift](../../native/Package.swift) declares local core/UI targets and no external package dependencies. The reviewed `native/Sources` contain no CloudKit, Keychain or authenticated-encryption implementation. App Groups share local storage between the phone app and keyboard; they do not establish cross-device sync.
- [Ticket 05](../../.scratch/native-mvp/issues/05-private-device-sync.md) is still `needs-info` and unchecked. No encrypted two-vault test or real-account two-device result is present in that ticket.
- [VaultModel.swift](../../native/Sources/MindMachineUI/VaultModel.swift) sends a query, six retrieved originals and recent conversation to a configurable Ollama-compatible endpoint. It distinguishes some loopback/private-network addresses from public hosts and requires the cloud toggle for the latter. It accepts HTTP URLs, and uses `URLSession.shared`; redirect handling, endpoint authentication and a complete destination policy have not been implemented or verified. Private-address classification does not establish that a remote service is trustworthy or local to the person.
- Target plists permit local networking, rather than globally disabling App Transport Security. Current target entitlements do not provision CloudKit or shared Keychain access.

These are source findings, not a penetration test. Nothing in current builds supports a claim that provider-unreadable sync is operating.

## Standards to turn into executable checks

Use [OWASP MASVS](https://mas.owasp.org/MASVS/) control groups with concrete MASTG tests for storage, crypto, authentication, networking, platform interaction, code and privacy. MASVS v2 moved the old level labels into testing profiles; choose and record the applicable tests rather than saying “MASVS compliant” after running unit tests. [OWASP's framework explanation](https://mas.owasp.org/news/archive/2026/) describes this separation.

For a future hosted billing/account/relay API, use [OWASP ASVS 5.0.0](https://asvs.owasp.org/) requirements for that service. This is the current stable version shown by the project, published 30 May 2025. It complements mobile checks; it does not attest to Apple's service or this implementation.

## Threat model to approve before implementing the key lifecycle

The following table is an application-specific proposal.

| Threat | Required protection | Boundary that remains |
| --- | --- | --- |
| Database/storage-provider breach or employee access | Contents, media, derived summaries and any uploaded embeddings encrypted before upload; no service-held decryption key | Provider can observe account association, timing, sizes and record traffic |
| Network interception | Platform TLS validation, no production HTTP, authenticated ciphertext | A compromised intended recipient can still read plaintext |
| Lost locked phone or Mac | Explicit protection for local data/indexes, protected Keychain keys, test locked/reboot states | An unlocked compromised OS can read active content and keys |
| Cloud account takeover/new device | Document trusted-device enrollment and recovery trust; no silent replacement key | If account recovery authorizes a device to obtain the vault key, that device can read it |
| Malicious or stale replica | Reject tampering; authenticate identities/versions; durable tombstones and conflict preservation | A provider can withhold data; freshness needs additional application state |
| Untrusted captured webpage/attachment | Treat retrieval as data; constrain rendering and model tools | Correct encryption does not prevent prompt injection |
| Supply-chain compromise | Pin/review dependency changes and signed releases; inventory shipped SDKs/models | A malicious signed client can exfiltrate content after decryption |
| Accidental disclosure | Neutral notifications, no note/query logs, deliberate Insert/export, separate cloud-AI consent | A destination chosen by the user retains its own copy |

Do not promise protection against an active, fully compromised authorized device or erase copies already exported. Do not call a design “zero knowledge” without specifying which provider and which metadata are covered.

## Apple platform facts and their consequences

Apple says third-party CloudKit encrypted fields/assets become end-to-end encrypted with Advanced Data Protection. Ordinary third-party iCloud data is encrypted in transit and on the server. Passwords/Keychain are separately end-to-end encrypted; some metadata remains readable to Apple even with ADP. Therefore the product's unconditional content-privacy promise should use application ciphertext independently of the user's ADP setting. [iCloud data security overview](https://support.apple.com/en-us/102651).

CloudKit's encrypted fields cannot be indexed; references must remain visible to the server, and losing/resetting the corresponding iCloud Keychain material can make encrypted data irrecoverable. Private/shared databases support encrypted fields; a public database is not the place for a personal vault. [Encrypting user data](https://developer.apple.com/documentation/cloudkit/encrypting-user-data). This supports keeping lexical/vector search indexes on the device. App-side ciphertext makes server content search unavailable as well.

For files, Apple's default class is protected-until-first-authentication. Complete Protection offers a stricter locked-state boundary on iPhone; Mac behavior is tied to login/logout and differs from the phone lock screen. Select and test each file class intentionally, including database journals, search indexes, model caches and export/temp files. Do not describe Mac lock behavior as identical to iPhone. [Data Protection classes](https://support.apple.com/en-ca/guide/security/secb010e978a/web).

Use the strictest Keychain accessibility compatible with the feature. [WhenUnlockedThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly) supports foreground use and does not migrate to another device. [AfterFirstUnlockThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly) permits background access after the first unlock, with a larger locked-state exposure. These are deliberate tradeoffs, not interchangeable defaults.

Synchronizable Keychain items cannot use `ThisDeviceOnly` classes. Their updates/deletions affect synchronized copies, and macOS uses the data-protection Keychain/access-group model for them. Thus a device-local wrapping key and a synchronized vault key have different roles. [kSecAttrSynchronizable](https://developer.apple.com/documentation/security/ksecattrsynchronizable). Shared access also needs explicitly configured, provisioned Keychain access groups for the appropriate targets. [Configuring Keychain sharing](https://developer.apple.com/documentation/xcode/configuring-keychain-sharing).

Keyboard Full Access permits shared-container writes and network use and requires explicit user action. This adds responsibility around ordinary host keystrokes. Persist only explicit private captures; keep host typing out of the vault/telemetry. The existing simulator grant says nothing about a real phone. [Configuring open access for a custom keyboard](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard).

## Proposed encryption and key lifecycle

Use [CryptoKit](https://developer.apple.com/documentation/cryptokit) primitives rather than implementing cryptography. AES-256-GCM is a candidate for record payloads. Its authenticated additional data should bind an unambiguous versioned envelope to the vault ID, opaque record ID, record type, key epoch and mutation identity, so moving ciphertext into a different context fails verification. Use library-generated random nonces; nonce reuse with one key breaks GCM's safety. [AES.GCM](https://developer.apple.com/documentation/cryptokit/aes/gcm), [nonce requirement](https://developer.apple.com/documentation/cryptokit/aes/gcm/nonce). This specifies an integration direction; it is not an audited protocol.

Before releasing sync, make the following states explicit and testable:

1. **Creation:** Only an online first-device initialization may create a canonical vault manifest/key identifier. Guard concurrent creators with server conflict semantics. Another device must wait for that exact key; “no local Keychain result” must never cause key replacement.
2. **Enrollment:** For the Apple-only pilot, synchronizable Keychain is a candidate low-friction route. Document dependence on the person's trusted Apple devices/account recovery. It does not provide independent per-device membership control. A custom trusted-device pairing protocol should use an established reviewed design if that stronger control is required.
3. **Key hierarchy:** Separate account/vault identities, random master key, versioned key epochs and device-local protection. Never put decryption keys next to ciphertext in preferences or CloudKit. An optional per-record data-key hierarchy makes rotation/deletion more flexible but adds lifecycle complexity that must be justified.
4. **Recovery:** Show what happens if all devices or the Keychain are lost. A recovery key/export must be generated and verified on-device; the service must not retain a plaintext recovery secret. If the pilot relies solely on Apple's recovery, say so plainly. Never silently create an empty replacement vault over inaccessible ciphertext.
5. **Revocation/rotation:** Changing authentication credentials does not revoke plaintext/key copies already on a device. A meaningful device-removal feature must stop future key delivery, rotate the appropriate epoch and handle offline replicas. Synchronizable shared secrets alone do not implement this guarantee. Name the pilot limitation before promising “revoke device.”
6. **Forget/deletion:** Replicate versioned tombstones and remove originals, snippets, embeddings, summaries, temporary caches and notification details. Test an old offline replica rejoining. Tombstone compaction needs an acknowledgment/retired-device or full-resync rule. Deleting one wrapped key does not erase historical copies when a retained master key or backup can still decrypt them.
7. **Account change:** Pause and isolate local data, pending mutations, keys and sync state by account/vault. Never upload the previous person's unsynced captures into a new account.

Deletion claims must distinguish disappearance from live interfaces, propagation to offline devices, provider backup retention and media sanitization. [NIST SP 800-88 Rev. 2](https://csrc.nist.gov/pubs/sp/800/88/r2/final) is the current final media-sanitization reference (September 2025); it does not establish that deleting an app database row physically erases flash media.

Apple now documents quantum-secure hybrid key exchange in CryptoKit. [Quantum-secure workflows](https://developer.apple.com/documentation/cryptokit/enhancing-your-app-s-privacy-and-security-with-quantum-secure-workflows) is relevant to long-lived sensitive ciphertext and future device pairing. Check API/platform availability against the current iOS 17/macOS 14 minimums before selecting it. Do not advertise post-quantum security from using AES or a recent SDK alone; the whole key-distribution path needs analysis.

## Sync architecture and measurable budget

Proposed modules: local transactional store → durable mutation/outbox → authenticated encryption envelope → transport adapter → verified inbound merge → local index update. One commit must durably save the source and its queued mutation before reporting success. Network retries must be idempotent. Original-content conflicts must remain recoverable; a timestamp-only last-write-wins rule can silently lose captures or revive deletions.

[CKSyncEngine](https://developer.apple.com/documentation/cloudkit/cksyncengine-4b4w9) handles automatic scheduling and some transient retries, but its background schedule is indeterminate. Applications must persist engine state and handle conflicts/account changes. Its explicit send/fetch methods enable a foreground fast path. This is the basis for the following **unmeasured proposed targets**, not an Apple SLA:

| Measurement | Proposed acceptance target | Conditions and evidence |
| --- | --- | --- |
| Save tap to durable local confirmation | p95 ≤50 ms for a ≤16 KB text capture | Release build on supported real devices, 10,000 captures, cold/warm runs reported separately |
| Saved capture discoverable on the same device | Lexical path immediately after commit; semantic enrichment asynchronous | A source remains findable while model/index work is pending |
| Durable text save to other active device searchable | p50 ≤1 s, p95 ≤3 s | Both apps active, keys present, healthy unthrottled connection; ≥100 mutations in each direction, measured over multiple sessions |
| Inbound apply to locally searchable | p95 ≤100 ms after receiving a small record | Excludes network wait and expensive optional enrichment |
| Relaunch after offline save | Zero lost acknowledged mutations; queue resumes | Kill/restart, duplicates, retries and network failures injected |
| Background/suspended device convergence | Record distribution and visible freshness; no fixed deadline promised | Real iPhone/Mac, locked/unlocked, low-power, denied permissions and intermittent network |

Avoid uploading a whole vault for each keystroke. Sync accepted small mutations promptly, batch safely, prioritize text over media, and enforce retry-after/backoff. Save/search UI must remain responsive during sync, encryption and indexing. CloudKit feasibility for the foreground target must be demonstrated with actual accounts; if measured latency misses the target, compare transports behind the same ciphertext boundary before changing the privacy contract.

## AI, dependency and consumer-surface safeguards

Retrieved originals, images and links are untrusted inputs. System-prompt instructions alone do not prevent injection; OWASP explicitly says RAG does not fully mitigate it. Keep credentials out of model context, restrict tools to explicit typed operations, validate identifiers/output in code, and require deliberate acceptance for external/privileged actions. Test malicious stored content trying to exfiltrate other notes, trigger reminders or alter retained facts. Disable automatic remote-image/link fetching in generated answers. [OWASP LLM01:2025](https://genai.owasp.org/llmrisk/llm01-prompt-injection/).

Production AI endpoints need authenticated transport, fixed/validated provider selection, explicit opt-in, and redirect/destination checks. Treat LAN services as external processors even when they require no cloud toggle; show where content goes. Keep hosted credentials in Keychain. Preserve ATS defaults and use narrow development exceptions. [Apple ATS guidance](https://developer.apple.com/documentation/security/preventing-insecure-network-connections), [local-networking scope](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking).

Pin dependency/model versions and hashes, review added install/build scripts and licenses, inventory transitive dependencies, and scan advisories at release. Keep build credentials scoped away from dependencies and release signing. Record source-to-artifact provenance; [SLSA v1.2](https://slsa.dev/spec/v1.2/) defines an incremental source/build framework. Using an open-source keyboard or Rust library adds this review obligation; it does not remove it.

Match actual app/SDK collection and required-reason API usage to bundled privacy manifests and store disclosures. Apple documents the manifest requirements and Xcode's aggregated reporting. [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files). Do not collect capture text, search queries, embeddings, typing histories or raw model requests in analytics/crash logs. Consumer settings should say “Private on this device,” “Sync,” and “Assistant,” while endpoint/diagnostic controls belong in a separate developer area or internal build.

## Verified security news in the requested week

Window: **15–22 October 2026** in the user's timezone. The following first-party publications fall within that period; they establish particular events, not that every app is under a new kind of attack.

| Publication and event date | Verified finding | Relevance to this app |
| --- | --- | --- |
| ConnectWise first advisory 16 October; updates through 21–22 October. Vendor says detection was 14 October, before this window. | Unauthorized access involved Cloud Backup application identities/credentials. ConnectWise disabled affected connections, reset credentials and began phased restoration. It reports encrypted archives preserved with no indication of compromise, while downstream live tenants require separate review. | Provider identity privileges and downstream access are distinct from encrypted archive protection. Keep local copies usable during outages; avoid broad service-held content credentials. There is no evidence in these notices that this app or CloudKit is affected. [ConnectWise advisory](https://www.connectwise.com/company/trust/advisories) |
| PHP release/security advisory 21 October; Dutch NCSC alert and update 21 October. | PHP published fixes for two critical unauthenticated RCE vulnerabilities, CVE-2026-109618 and CVE-2026-109619. NCSC advised rapid updating and precautionary shutdown pending patches. | Reviewed native code has no PHP dependency or PHP service. This supports inventorying and patching actual components; adding Rust does not address an absent PHP component. [PHP security advisory](https://www.php.net/archive/2026.php#2026-10-21-1), [NCSC patch notice](https://www.ncsc.nl/alerts/kwetsbaarheden-php-patches-beschikbaar-update-nu) |

The news changes the urgency of release verification; it does not justify claiming that an unaudited encryption layer follows every current security guideline. No secondary aggregator headline was treated as proof of an incident.

## Release gates

All gates below are **pending** for encrypted sync as of this source review:

- Approve the threat model and record key creation/enrollment/recovery/revocation semantics in an ADR. Identify precisely which providers cannot decrypt content and what metadata remains visible.
- Through the approved encrypted two-vault seam, test tampering, wrong keys, substituted identities, duplicate/reordered/replayed mutations, nonce generation, concurrent initialization, old key epochs and missing-key states. AEAD authenticity alone does not prove freshness.
- Demonstrate offline saves, conflict preservation, crash recovery, rate limiting, account changes, and deletion without resurrection, including a device offline longer than tombstone retention.
- Inspect real CloudKit records, request bodies, logs, backups, temporary files and search indexes for plaintext/content-derived leaks. Ensure encryption migrations never leave the old JSON/index behind unintentionally.
- Run a signed real iPhone plus Mac through initial enrollment, recovery/key delay, both sync directions, keyboard extension relaunch, foreground/background, lock/reboot, permission denial and reminder cancellation reconciliation. Simulator success alone does not satisfy this gate.
- Publish measured latency distributions, device/OS/corpus/network conditions and resource use. Distinguish active-device latency from OS-scheduled background convergence.
- Complete targeted MASTG/ASVS control mapping, dependency/signing/privacy-manifest checks and an independent security review of key lifecycle and replication before broad public release. Track findings as defects; do not imply certification from this document.

The next useful security milestone is an executable encrypted two-vault pilot with a documented key lifecycle. It should precede a user-facing “private sync ready” claim.
