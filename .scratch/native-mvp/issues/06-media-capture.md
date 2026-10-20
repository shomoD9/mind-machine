# 06 — Capture media and recover its original

Status: ready-for-agent
Blocked by: 01
Spec: [Native MVP](../spec.md)
Review baseline: c319917

## Acceptance criteria

- [ ] Provide supported image/audio/file input through permitted native paths; the keyboard cannot secretly access a microphone.
- [ ] Persist original attachments and visible processing state before extraction. Failures preserve originals.
- [ ] Supported OCR/transcript retrieval links to originals and declares formats/storage/processing limits.
- [ ] Use a deliberate companion capture route where keyboard APIs prohibit capture. Verify sync integration with ticket 05 at release.

## Verification

Record executable evidence and remaining limitations here. Compilation, simulator behavior and real-device proof are separate facts.

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Waiting for the listed blockers.
- 2026-10-20: Ticket 01 resolved; implementation dependency cleared. Remains unclaimed while ticket 02 is worked.
