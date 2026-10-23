# 02 — Deleting one copy of a conflicted note removes every copy

Status: needs-info
Blocked by: product decision on what "delete" means for a note with conflict copies; no screen deletes today
Spec: [State machines](../spec.md)
Found by: `spec/shipped-DeleteSparesOtherCopies-causal.cfg`, `spec/shipped-NoCapturedNoteLost.cfg`
Baseline: origin/main `c45031b`

## What happens

When two devices edit one note offline, Recall shows both versions as separate copies. If a person removes one copy, the other copy disappears with it on every device. The person did not ask to remove it.

## TLC counterexample (parents always arrive first)

1. Mac captures a note and changes it (revisions 1 and 2). The iPhone fetches revision 1 and makes its own change (revision 3, parent 1).
2. Revision 2 reaches the iPhone. Recall shows two copies, 2 and 3.
3. The person removes one copy on the iPhone. A tombstone (revision 4) is created.
4. Both copies are hidden. The copy the person kept is gone.

TLC's shortest example happens to use equal contents for 2 and 3; the code does not look at contents, so the same holds when they differ.

## Code path implied

`VaultFile.update`, the loop over captures removed from the vault (line 134), creates `NoteRevision(noteID:, capture: nil, parents: heads(note))`. Its parents are all current heads, not only the removed copy. `VaultFile.materialize` returns early when any tombstone exists for the note (line 345), so every branch is hidden. `ReplicationTests.testOfflineConcurrentOriginalsConvergeWithoutResurrection` locks in "a delete dominates a stale replica" and still passes if deletes name only the copy they remove.

## Why it is not a defect yet

No screen removes a capture. The path is reachable from tests and from the planned "Forget this" feature (`CONTEXT.md`). Decide the rule before that feature ships.

## Options

1. A tombstone names the revisions it removes. Other branches stay visible. This is the design in `spec/fixed-safe.cfg` (`TombstoneRule = "Ancestry"`).
2. Removing a copy removes the note by design. Then the confirmation text must say so, and the TLC rule moves to a documented exception.

## Acceptance criteria

- [ ] The human chooses option 1 or 2 and records it in `docs/DESIGN.md`.
- [ ] Option 1: `fixed-safe.cfg` passes; `shipped-DeleteSparesOtherCopies-causal` and `shipped-NoCapturedNoteLost` flip to `pass` with the Swift change; a deleted copy stays deleted when an older replica is redelivered (`DeletedStaysDeleted` still passes).
- [ ] Option 2: the rules are rewritten in `spec/MindMachineSync.tla` as intentional, with the UI wording as evidence.
