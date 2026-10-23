# 04 — An older version shows beside the newer one when revisions arrive out of order

Status: ready-for-agent
Blocked by: none
Spec: [State machines](../spec.md)
Found by: `spec/shipped-NoStaleCopyBesideNewer.cfg`
Baseline: origin/main `c45031b`

## What happens

A note changes twice on one device (versions 1, 2 and 3). The other device receives versions 1 and 3 first. Until version 2 arrives, Recall shows version 1 and version 3 as two copies. It converges when version 2 arrives; in between a person sees a stale copy and may act on it (open it, set a reminder, tick an item).

## TLC counterexample

1. Mac captures a note (revision 1) and changes it twice (revisions 2 and 3).
2. The Mac uploads revision 1, then revision 3. Revision 2 is still waiting.
3. The iPhone fetches 1 and 3. Revision 3's parent (2) is missing, so revision 1 still counts as a head.

## Code path implied

`VaultFile.pendingRevisions` returns pending rows newest first, at most 100 (line 301). `PrivateCloudSync.nextRecordZoneChangeBatch` sends them in that order and builds a dictionary from them, so the send order is not guaranteed even then. `VaultFile.heads` only knows revisions that are present. After more than 100 pending revisions, the batch limit alone splits parents from children across fetches.

## Acceptance criteria

- [ ] A revision is sent only after its parents are acknowledged or are in the same batch, or `materialize` hides a revision's known ancestors even when the revision between is missing.
- [ ] `shipped-NoStaleCopyBesideNewer` flips to `pass` with the Swift change; `fixed-safe.cfg` (with `UploadParentsFirst = TRUE`) already passes, and `fixed-without-parents-first-NoStaleCopyBesideNewer` stays a documented violation unless the second option is taken.
- [ ] A test uploads 150 pending revisions of one note in a chain and checks that no fetch shows two copies.
