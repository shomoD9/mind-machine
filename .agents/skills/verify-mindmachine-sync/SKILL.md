---
name: verify-mindmachine-sync
description: Model-check Mind Machine's sync and shared-vault code with TLC before and after changing it. Use when a change touches VaultFile.swift revisions/merge/materialize/acknowledge, PrivateCloudSync.swift, NoteRevision.swift, the App Group vault shared by app and keyboard, or how a note is deleted or conflict-copied. Also for "model-check sync", "can a note be lost", "run TLC".
---

# Verify Mind Machine sync

Generated with `/create-formal-verification-skill` (pstack 0.15.30). The model is `spec/MindMachineSync.tla`. It checks every order of captures, edits, deletes, uploads, acknowledgements, fetches and process crashes for one phone vault (app and keyboard share it) and one Mac vault, up to 4 revisions of one note.

## What it protects

A note a person captured is never lost, a note seen in Recall reaches the other device, and Recall never shows two copies of the same note. A break here loses a person's thought without any error on screen.

## Decide whether your change is in scope

Run the check when your diff touches any of these (paths under `native/Sources/MindMachineCore/`):

| File and function | Why |
| --- | --- |
| `VaultFile.swift`: `append`, `update`, `merge`, `acknowledge`, `pendingRevisions`, `queue`, `heads`, `identity`, `materialize`, `bindSyncAccount` | These are the model's Capture, Edit, Delete, Ack, Fetch and Visible. |
| `PrivateCloudSync.swift`: `synchronize`, `handleEvent`, `nextRecordZoneChangeBatch` | Register, Save, Ack, Fetch. |
| `NoteRevision.swift` | Revision shape: parents, tombstone. |
| App Group path or open flags in `Apps/Shared/DeviceVault.swift`, `VaultFile.open` | Who shares the store. |
| A new screen that deletes, merges or edits a note | Adds a person action the model does not have yet. |

Search ranking, FTS, UI layout and reminders do not need this check.

## Run it

```sh
spec/run-tlc.sh              # all configs, several minutes with 8 cores; the liveness configs are the slowest
spec/run-tlc.sh fixed-safe   # one config
MM_TLC_SHOW=1 spec/run-tlc.sh shipped-NoDuplicateCopies   # print the counterexample
```

The script needs Java 17+ and downloads `tla2tools.jar` 1.7.4 to `~/.local/mm-tla` (SHA-256 pinned in the script). Set `JAVA` and `TLA2TOOLS` to use your own. Each `spec/*.cfg` starts with `\* expect: pass` or `\* expect: violation: <Rule>`. The script prints `ok` when the result matches. It exits 0 only if all do.

## Read the result

State at the sync commit below:

| Config | Expected | Meaning |
| --- | --- | --- |
| `shipped-safe`, `shipped-converges` | pass | Shipped code keeps deleted notes deleted, and both devices end up identical. |
| `shipped-NoDuplicateCopies-causal` (parents arrive first), `shipped-NoDuplicateCopies` (any order) | violation | Ticket `.scratch/state-machines/issues/01` (the second also shows 04). |
| `shipped-DeleteSparesOtherCopies-causal`, `shipped-DeleteSparesOtherCopies` | violation | Ticket 02. |
| `shipped-NoCapturedNoteLost` | violation | Tickets 02 and 03 (a note vanishes). |
| `shipped-DeleteSparesUnseenEdits` | violation | Ticket 03. |
| `shipped-NoStaleCopyBesideNewer` | violation | Ticket 04. |
| `fixed-safe`, `fixed-converges` | pass | The proposed fixes (tombstone names what it deletes, identical heads fold, parents upload first) remove all four. |
| `fixed-without-parents-first-NoStaleCopyBesideNewer` | violation | Folding and tombstones do not fix ticket 04 alone. |
| `broken-ack-early` | violation | Proves the liveness check can fail: acknowledging before upload loses notes. |

- A **new** violation, or a `shipped-safe` / `shipped-converges` failure, is a real regression until shown otherwise. Read the counterexample as a list of steps; each action name is one function in the table above.
- A config that now **passes** where a violation was expected means a ticket was fixed. Change its `expect` line to `pass`, move the rule into `fixed-safe`'s role, and close the ticket with the TLC output as evidence.
- A modelling error shows up as a step the code cannot take (for example a Fetch that returns a record nobody uploaded). Fix the model and say why in the comment above the action.

## Update the model when a change is intended

1. Change the matching action in `spec/MindMachineSync.tla` and keep the `file:line` comment on it.
2. Add a person action for a new screen (delete, merge) with the same parent rules the code uses.
3. Run all configs. Never weaken a rule or delete a config to get green.
4. Update `docs/state-machines/software.md` and `product.md` first, per `AGENTS.md`.

## Coverage record

- Last confirmed against origin/main `c45031b` (`chore(core): replace getstatemachine identifier prefix with statemachine`).
- Move this commit forward only after you reread the functions in the table above at the new commit and confirm the model still describes them.
- Verified: for one note, up to 4 revisions, 2 values, 3 sync processes, one crash, any interleaving, any delivery order of cloud records. Liveness configs use 3 revisions.
- Not verified: encryption and keys; account change and the stopped state (see `software.md` S1, S2); the 100-row batch limit; SQLite busy errors; more than one note; reminders and chat (never synced); the real CloudKit service; Swift code itself. A pass covers the model, not the app.
- Assumptions: SQLite transactions are atomic; each process runs its sync loop again and again; crashes stop repeating; CloudKit returns every saved record to every cursor eventually.

## Known limit of this skill

It was proven on the model (the `broken-ack-early` and `shipped-*` configs fail as expected). It was not proven by changing the Swift code, because the box that wrote it has no Swift toolchain and the task forbade app-code edits. The first agent that changes `VaultFile.merge` or `acknowledge` on a Mac should make a scratch break there (for example acknowledge before the CloudKit save) and confirm the matching config would catch the same step, then record that here.
