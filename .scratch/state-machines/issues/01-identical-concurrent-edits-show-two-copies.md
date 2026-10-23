# 01 — Identical edits on two devices show two copies of one note

Status: ready-for-agent
Blocked by: none
Spec: [State machines](../spec.md)
Found by: `spec/shipped-NoDuplicateCopies-causal.cfg` (rule "Recall never shows two copies of one note with identical content")
Baseline: origin/main `c45031b`

## What happens

A person ticks the same checklist item on the Mac and on the iPhone before the devices have synced. After sync, Recall shows the list twice. Both copies have the same text and the same ticked item. Nothing tells the person why, and no action merges them.

## TLC counterexample (parents always arrive first)

1. The Mac captures a note (revision 1, value a).
2. The Mac changes it to value b (revision 2, parent 1) and uploads revision 1.
3. The iPhone fetches revision 1.
4. The iPhone makes the same change to value b (revision 3, parent 1).
5. Revision 2 reaches the iPhone. The iPhone now holds two revisions with parent 1 and identical content.

Both are heads, so both are shown.

## Code path implied

`VaultFile.update` creates one revision per edited capture with the displayed copy's revision as parent. `VaultFile.heads` returns every revision that no other revision names as parent. `VaultFile.materialize` writes one visible capture per head, with identical text and checklist when the edits were identical. Nothing compares content between heads. Only checklist toggles edit note content today (`VaultModel.setItem`), so this needs two devices toggling the same item, which is the normal way to use one list on two devices.

## Acceptance criteria

- [ ] Heads of one note with identical content show as one copy on every device, and the copy keeps one stable identity.
- [ ] `spec/fixed-safe.cfg` passes with `CollapseIdentical = TRUE`, and the shipped-code config for the same rule is changed to `expect: pass` in the same change that fixes the Swift.
- [ ] A saved-vault test reproduces the five steps above through the public replication boundary (`ReplicationTests`) and fails before the change.
- [ ] `docs/state-machines/software.md` section 1 (note projection) is updated first.

## Comments

- Interaction: ticket 02 changes what deleting a displayed copy does. A person who finds the duplicate and deletes one copy loses the other too under the shipped code.
