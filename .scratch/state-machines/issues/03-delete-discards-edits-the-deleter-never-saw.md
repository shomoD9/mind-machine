# 03 — A delete on one device discards an edit made on another device

Status: needs-info
Blocked by: 02 (same tombstone rule)
Spec: [State machines](../spec.md)
Found by: `spec/shipped-DeleteSparesUnseenEdits.cfg`
Baseline: origin/main `c45031b`

## What happens

The Mac changes a note while offline. The iPhone, which has not seen that change, removes the note. After sync the Mac's change is hidden on both devices. No message says an edit was dropped.

## TLC counterexample

1. The Mac captures a note and changes it (revisions 1 and 2) and uploads revision 1.
2. The iPhone fetches revision 1 and removes the note (tombstone, revision 3, parent 1).
3. Revision 2 reaches the iPhone. It is a head and is not named by the tombstone, but it is hidden.

## Code path implied

`VaultFile.materialize` line 345: "A logical-note tombstone dominates stale branches". The code treats every revision of the note as stale, including revisions the deleting device never had.

## Decision needed

This may be the right behaviour: delete wins, and it is what `docs/MVP-CORE.md` asks for ("prevent deleted material returning from stale replicas"). The product question is whether an edit the deleter never saw is stale. Option 1 in ticket 02 keeps such an edit visible as the note's only copy. Option 2 drops it.

## Acceptance criteria

- [ ] The human records the rule in `docs/DESIGN.md`.
- [ ] If edits survive a delete: `fixed-safe.cfg` passes and `shipped-DeleteSparesUnseenEdits` flips to `pass` with the Swift change.
- [ ] If delete wins: the rule is rewritten in the spec as an intentional exception, with a test that names it.
