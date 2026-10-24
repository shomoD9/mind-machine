# 21: Version the CloudKit production schema and deployment steps

Status: claimed
Blocked by: none for repository work; Shomo performs Console deployment and signed-device verification separately

## Acceptance criteria

- [x] Add `native/CloudKit/schema.ckdb` with one app record type, `MindMachineRevisionV1`, and one field, `sealedRevision ENCRYPTED BYTES`.
- [x] Check every CloudKit caller and container configuration; establish that the runtime zone requires no record type or extra fields.
- [x] Document Development creation, deployment diff review, irreversible additive-only Production deployment and schema/device verification for Shomo.
- [x] Leave workflows, app code, secrets and `docs/PRODUCT.md` untouched; update DESIGN and the journal.
- [ ] Commit and push `cloudkit-schema`, open the requested PR, leave it unmerged and write `/tmp/mm-ck-result.md`.

## Comments

- 2026-10-24, GPT-6 / Codex API (mm-ck): Claimed the user-authorized repository task after reading tracker, triage, domain and ADR guidance. Production deployment remains a manual action outside this task.
- 2026-10-24, GPT-6 / Codex API (mm-ck): Reviewed the schema against Apple's grammar and all CloudKit source references. A Python comparison passed for the sole record constructor, four encrypted-field accesses, AES-GCM sealing, runtime zone saves, private database, configured container and README links; `git diff --check` passed. Swift/Xcode/cktool are unavailable on this Linux workspace, so no CloudKit service validation or signed-device claim is made.
