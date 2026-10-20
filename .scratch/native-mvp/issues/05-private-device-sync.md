# 05 — Use the same private vault on iPhone and Mac

Status: needs-info
Blocked by: 01, 03, 04
Spec: [Native MVP](../spec.md)
Review baseline: c319917

## Acceptance criteria

- [ ] Replicate app-encrypted per-record payloads through the configured CloudKit adapter; plaintext local JSON must never be the uploaded sync payload.
- [ ] Guard first-device manifest/key creation. Other devices wait for the matching key instead of generating a replacement. Isolate account changes.
- [ ] Durable offline mutations retry, preserve conflicts, propagate deletions without resurrection and reconcile local notifications.
- [ ] Prove encrypted two-vault behavior through the approved replication interface; real-account two-device success is separate required evidence.
- [ ] Provide signing/entitlement setup and clear key-wait/recovery status. Do not claim sync based on a local adapter alone.

## Verification

Record executable evidence and remaining limitations here. Compilation, simulator behavior and real-device proof are separate facts.

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Waiting for the listed blockers.
