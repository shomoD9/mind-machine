# 05 — Resolve the mismatches between the charts and the code

Status: needs-info
Blocked by: product decisions G1 to G4 in `docs/state-machines/product.md`
Spec: [State machines](../spec.md)
Found by: reading the code against the product chart (not TLC)
Baseline: origin/main `c45031b`

The list is in `docs/state-machines/software.md` sections 6 (M1 to M11) and 7 (S1 to S7). Highest impact first:

1. **S1 and S2: sync pause has no exit.** One unreadable cloud record, a deleted cloud zone or a changed iCloud account stops sync on that device for good. Relaunch meets the same record again. Decide what a person does about it.
2. **M1 and M2: Full Access off.** The keyboard lets a person type a note it cannot save, and it never notices Full Access being turned on while it is loaded.
3. **M4 and M5: the keyboard shows no sync status, and "offline" is not a named state.**
4. **M9 and M10: Copy and Insert on the Mac; first-sync progress.** Both are promised in `docs/MVP-CORE.md`.
5. **M11: the note id moves between conflict copies.** Reads from the code only; reproduce on a Mac first.

## Acceptance criteria

- [ ] Each of M1 to M11 and S1 to S7 is fixed, accepted as intended (chart updated) or split into its own ticket.
- [ ] The product chart and software chart are updated first for each change.
- [ ] Split S1 and S2 into tickets only after the human answers G1 and G2.
