# CloudKit production schema

Shomo deploys [schema.ckdb](schema.ckdb) to container `iCloud.com.statemachine.mindmachine` through the [CloudKit Console](https://icloud.developer.apple.com/). This file declares the complete app schema: one record type, `MindMachineRevisionV1`, with one field, `sealedRevision ENCRYPTED BYTES`. Committing this file or uploading a TestFlight build does not deploy the schema.

## Match the app

- [PrivateCloudSync.swift](../Sources/MindMachineCore/PrivateCloudSync.swift) creates `CKRecord(recordType: "MindMachineRevisionV1", ...)`, writes `RevisionCipher.seal(...) as NSData` to `record.encryptedValues["sealedRevision"]`, and reads that same encrypted field for fetches and duplicate-upload checks. There is no ordinary record-field copy of the payload.
- [RevisionCipher.swift](../Sources/MindMachineCore/RevisionCipher.swift) uses AES-GCM before CloudKit receives the payload. Notes, revision metadata and tombstones travel inside those sealed bytes. They need no separate CloudKit fields or record types.
- `PrivateCloudSync` uses `container.privateCloudDatabase`. `MindMachinePrivateV1` is a custom per-user zone, created at runtime through `.saveZone(CKRecordZone(zoneID: zone))`. Do not create a record type with that name or manually provision users' zones.
- [MindMachine.xcconfig](../Config/MindMachine.xcconfig) sets `VAULT_ICLOUD_CONTAINER`; the generated Info.plists and entitlements reference it. [VaultModel.swift](../Sources/MindMachineUI/VaultModel.swift) passes the resolved `VaultCloudContainer` to this adapter. The repository has no other CloudKit record writer. No additional app record type, field, index or public-database grant is required by the current app in Production. CloudKit's built-in types and system metadata remain implicit.

## Create in Development and deploy

1. Sign in to the CloudKit Console with the Apple developer account for Mind Machine. Select the signing team and open **CloudKit Database**. Deployment requires permission to edit Production.
2. Select container **iCloud.com.statemachine.mindmachine** and environment **Development**. Recheck both before editing.
3. Under **Schema → Record Types**, select **+**, enter the name **MindMachineRevisionV1**, and click **Create Record Type**. If it already exists, open it and inspect its fields instead of creating another type. [Apple's schema-editing instructions](https://developer.apple.com/documentation/cloudkit/inspecting-and-editing-an-icloud-container-s-schema) describe these controls.
4. Click **Add** beside **Record Fields**. Name the single field **sealedRevision**, select type **Encrypted Bytes** (the text schema spells this `ENCRYPTED BYTES`), and click **Save Changes**. Leave indexes unset. Do not choose ordinary **Bytes**, add a plaintext fallback, or add other app fields. If `sealedRevision` already exists as an unencrypted field, stop: Apple does not support converting an existing unencrypted field to encrypted. Resolve that mismatch before deployment. [Apple's encrypted-field instructions](https://developer.apple.com/documentation/cloudkit/encrypting-user-data) describe creation and this restriction.
5. Compare the saved Development type with [schema.ckdb](schema.ckdb). Check the exact spelling, encrypted bytes type and absence of extra app fields. Click **Export Schema…** in the sidebar and compare the downloaded Development declarations as well; built-in types, implicit system fields and ordering may differ. [Apple's Console export guidance](https://developer.apple.com/forums/thread/852738) identifies that action; the [text-schema grammar](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow) defines implicit entries.
6. Select **Deploy Schema Changes** in the left sidebar. Read the pending change diff against Production before pressing **Deploy**. The only intended app change is `MindMachineRevisionV1` with `sealedRevision ENCRYPTED BYTES`, or the missing part of that definition if partially deployed. Stop if the diff includes `MindMachinePrivateV1` as a record type, an unencrypted payload, unrelated types, fields, indexes or permission changes. If nothing is pending, verify the existing Production definition below.
7. After checking the diff, click **Deploy** and confirm the Console's prompt. Production schema deployment is **irreversible and additive-only for record types and fields**: deployed types/fields cannot be deleted, and reverting this file cannot undo deployment. Deployment promotes schema without copying Development records. [Apple's deployment instructions](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema) explain these constraints.

## Verify

1. Switch the Console to **Production**, recheck the container, and inspect **Schema → Record Types → MindMachineRevisionV1**. Confirm `sealedRevision` is **Encrypted Bytes**, with no plaintext companion field or extra app fields. Export the Production schema and check the equivalent `sealedRevision ENCRYPTED BYTES` declaration. Save the reviewed diff and deployment confirmation without private record contents or recovery keys.
2. Recheck the source from the repository root:

   ```sh
   rg -n 'CKRecord\(|encryptedValues|saveZone|privateCloudDatabase' native/Sources
   rg -n 'import CloudKit|CKContainer|CKDatabase|CKQuery|CKAsset' native
   rg -n 'VAULT_ICLOUD_CONTAINER|VaultCloudContainer' native/Config native/Apps native/Scripts/generate_project.py
   cat native/CloudKit/schema.ckdb
   ```

   Expect one record construction, the same encrypted field on every payload access, runtime zone saves and the configured container. Investigate any new CloudKit writer before treating this schema as complete.
3. On signed iPhone and Mac builds using **Production** (TestFlight/distribution builds), use the same iCloud account and pair the same existing private sync key. Create a disposable capture on iPhone, activate Mac and confirm the original arrives; create another on Mac and confirm it arrives on iPhone. Keep both apps active for these foreground exchanges. Repeat with captures saved offline, then reconnect. See [TESTING-TONIGHT](../../docs/TESTING-TONIGHT.md) for device setup. The current UI has no general note edit/delete workflow; deterministic replication tests cover those cases separately.
4. In Production's **Private Database**, inspect that account's runtime zone **MindMachinePrivateV1** and uploaded **MindMachineRevisionV1** records. Confirm the only app payload field is encrypted `sealedRevision`; no note text, revision metadata or recovery key should appear in plaintext CloudKit fields. If record browsing requests a query index, use record-ID lookup or Console Logs rather than changing this schema to support browsing. Check Production Logs for schema/type/field errors and each client's sync status. Record device/build versions and both transfer directions as acceptance evidence.

Repository checks establish the schema/code match. Production deployment and live two-device sync remain unverified until Shomo performs these steps.
