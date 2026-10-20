# Native pilot: encrypted sync and distribution

Research date: 20 October 2026. Official Apple documentation and Apple's sample repository reviewed. No credentials, provisioning profiles, containers, keys, devices, or account settings were inspected or changed. No app code was implemented. Findings describe a proposed architecture; successful cross-device operation remains untested.

## Recommendation

Build the native pilot with a local store on each device, a private CloudKit database carrying app-encrypted payloads, and a vault key synchronized through iCloud Keychain. Keep key establishment explicit and fail closed when an existing vault's key has not arrived. A private pilot can include real sync. Restricting distribution reduces onboarding and support work; it does not remove encryption, conflict, deletion, or entitlement requirements.

Apple's own [CKSyncEngine sample](https://github.com/apple/sample-cloudkit-sync-engine) requires an active Apple Developer Program membership, a signed app and CloudKit container, and the same iCloud account on participating devices. Its automatic sync uses remote notifications; a simulator-only demonstration is insufficient. Existing environment evidence supplied to this research task reports zero valid signing identities. That establishes a current signing gap, not whether the human owns a paid membership.

## Privacy boundary

CloudKit's ordinary transport/storage encryption does not by itself establish that providers cannot read vault contents. Apple states that standard protection keeps many keys in its data centers; third-party CloudKit encrypted fields/assets gain end-to-end protection with Advanced Data Protection. Therefore do not describe a normal private database as automatically end-to-end encrypted for every user. [Apple iCloud data security](https://support.apple.com/en-us/102651).

For this product's stronger default promise, serialize sensitive content locally, encrypt with a random vault key using CryptoKit AES-GCM, and upload the sealed bytes. AES-GCM's sealed box includes nonce, ciphertext and authentication tag; opening requires the key. Use library-generated nonces, authenticate stable record identity/version where appropriate, and avoid writing plaintext into record names, debug logs, analytics or push payloads. This is an architectural inference using [CryptoKit's authenticated-encryption primitive](https://developer.apple.com/documentation/cryptokit/aes/gcm/sealedbox), not an audited security implementation.

Store the vault key as a synchronizable keychain item, using a deliberately configured common access group and key identifier. Apple documents synchronization across iCloud, macOS data-protection-keychain behavior, cross-device updates/deletions and incompatibility with `ThisDeviceOnly` accessibility. [kSecAttrSynchronizable](https://developer.apple.com/documentation/security/ksecattrsynchronizable), [kSecAttrAccessGroup](https://developer.apple.com/documentation/security/ksecattraccessgroup). Apple describes iCloud Keychain as encrypted end-to-end between trusted devices. [iCloud Keychain security](https://support.apple.com/guide/security/icloud-keychain-security-overview-sec1c89c6f3b/web).

This leaves Apple-account/device trust and key recovery dependent on iCloud Keychain. It does not provide cross-account sharing or a future independent sync backend. CloudKit still sees account association, record identifiers, sizes, changes and traffic timing. Searches and derived indexes should stay on-device. Cloud AI remains separately opt-in.

## First-device key race

An empty local keychain query must never mean “replace the vault key.” Keys and CloudKit records can arrive separately; an offline device cannot prove a vault does not exist. No reviewed API promises immediate keychain delivery or a cross-service transaction between Keychain and CloudKit.

Proposed pilot protocol, requiring implementation and adversarial tests:

1. Initialize the vault online on one designated device. Create a uniquely identified keychain key and a fixed-ID CloudKit vault manifest containing the key identifier and format version, with create/conflict protection.
2. Fetch the manifest before allowing another device to initialize. Existing manifest plus absent matching key means **Waiting for vault key**; keep ciphertext intact and do not create a replacement.
3. If simultaneous initialization is attempted, only the canonical server manifest may win. Preserve any competing keys until reconciliation; never upload captures under the losing key. CloudKit documents record conflicts and requiring retries based on the server record. [serverRecordChanged](https://developer.apple.com/documentation/cloudkit/ckerror/serverrecordchanged).
4. If the key cannot be recovered, report a locked vault. Do not silently reset it. A deliberate destructive reset/recovery flow is additional scope.

A sequential founder-only setup is a tangible pilot simplification. It reduces the initial key-establishment surface while retaining an explicit guard against accidental dual initialization. The fixed-record creation semantics and Keychain convergence must be tested; this report does not certify the protocol.

## Local persistence, conflicts and deletion

Prefer individual encrypted records for captures, exchanges, checklist state and reminders; avoid a single encrypted whole-vault blob that makes every edit a conflict. Persist the local mutation queue and sync state durably. Apple requires applications to persist CKSyncEngine state and handle application-specific errors. [StateUpdate](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/stateupdate), [CKSyncEngine](https://developer.apple.com/documentation/CloudKit/CKSyncEngine-5sie5).

Pilot design recommendations:

- Preserve conflicting note revisions rather than silently choosing a winner. Make capture IDs immutable and retry saves idempotently.
- Represent deletion with a versioned tombstone until all supported clients reconcile. Remove plaintext originals and derived local search/memory content. Ensure stale offline edits cannot resurrect a forgotten exchange. Tombstone retention and conflict policy are product/application choices, not CloudKit guarantees.
- Reconcile reminder cancellation/editing and completed checklist state before scheduling local notifications. Sync completion does not itself cancel already scheduled notifications on another offline device; this must be handled and its offline limitation disclosed.
- Separate local stores and keys by vault/account. On account change, pause synchronization and protect unsynced local work from accidental upload into another person's account. Apple resets pending CKSyncEngine changes on account changes; the application must update persistence. [AccountChange](https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5/event/accountchange).

## Keyboard and entitlement constraints

Use a native iPhone container app plus keyboard extension. Give both a registered App Group for shared local persistence. App Groups are device-local sharing containers, not cross-device sync. Register matching memberships and provisioning entitlements for the relevant targets. [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups), [enabling capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/).

A keyboard without Full Access may read the containing app's shared container but cannot write it or use the network. Vault capture through a shared store therefore needs `RequestsOpenAccess` and the user's **Allow Full Access** setting. Keep basic typing and next-keyboard switching functional without that permission, and explain explicitly which app features need it. [Open-access keyboard configuration](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard), [App Review 4.4.1](https://developer.apple.com/app-store/review/guidelines/).

Do not retain ordinary host-field typing as vault captures. Explicit Save/Send to the vault and Insert into host must be distinct actions. The proposed chat/vault keyboard's review acceptance remains unverified. Share database access safely across processes; avoid assuming the container app is always running. Foreground refresh can be the honest first sync path, with visible pending/synced status; automatic keyboard-to-Mac propagation while the app is suspended requires additional device testing and a deliberate sync-owner design.

## Schema and delivery

Create a minimal versioned schema in development, test it, then deploy that schema to production before TestFlight. Deploying copies schema, not user records. Production changes are additive; existing record types/fields cannot simply be removed or renamed. [Deploying a CloudKit schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema). Apple's archived deployment guide explicitly states that uploads for TestFlight/App Store use production. [CloudKit environment guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/DesigningforCloudKit/DesigningforCloudKit.html).

Development installation on registered devices can avoid external beta review, with valid signing/provisioning still required. TestFlight internal testing supports eligible App Store Connect team users; external testing is for broader testers and the initial build requires TestFlight review. A public link does not bypass this dependency. Store release has a separate review/distribution path. [Distribution methods](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases/), [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/), [TestFlight](https://developer.apple.com/testflight/).

Thus a private native pilot offers faster controlled installation and sequential setup, while a public pilot adds onboarding, privacy disclosures, account/key failure handling, tester management and external review. The core app can be shared; the delivery readiness differs. No same-day Apple approval time is promised.

## Required proof before claiming launch

Validate actual signing/capabilities; install on the founder's real iPhone and Mac; demonstrate explicit keyboard capture, local persistence and search, Mac global hotkey, encrypted upload, second-device key availability and decryption, offline queue recovery, conflicting edits, deletion without resurrection, reminder edit/cancellation, disabled Full Access, and sign-out/account-change isolation. Check logs and CloudKit records for plaintext leakage. Record which of these have passed rather than inferring success from compilation.
