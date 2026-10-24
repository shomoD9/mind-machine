# 22: Capture window: lighter layout, remove top formatting row, clearer copy

Status: claimed
Blocked by: none

Founder request (2026-10-25): the Mac pill Capture window is wasteful, heavy and inelegant. Visual layout and copy only. The Markdown live-editing engine, storage, sync, performance code, keyboard, workflows, signing, entitlements and `docs/PRODUCT.md` are out of scope.

## Acceptance criteria

- [ ] The Bold / Italic / bullet / checkbox row is gone from the Capture window, with no dead or half-working formatting controls left in the shared editor. The text area is plain until the Markdown ticket lands.
- [ ] Chrome is tighter: calm Capture / Recall / Soon tabs, a refined prompt line, a quiet footer and Save as the one primary action with its shortcut hint.
- [ ] "No filing needed" is removed or replaced with clear copy. Sync state appears only when it matters, with details on demand.
- [ ] Recall, the original reader and the Soon slot look coherent with the new style.
- [ ] Existing UI tests and the pill self-test still guard what they guarded; any reference to removed controls is updated without weakening it.
- [ ] Before/after snapshots from the existing self-test mechanism are in `docs/verification/`.
- [ ] PR titled "Capture window: lighter layout, remove top formatting row, clearer copy" is open with a design rationale, CI is green or failures are explained at the root, and it is not merged.

## Comments

- 2026-10-25, Claude Opus 5.5 / Claude Code (mm-pill): Claimed. Read WorkspaceView, RichNoteEditor, PillPanelView, PillRootView, PillSelfTest, PillAcceptanceTests, DESIGN and the tracker/domain guidance. Before snapshots come from main's native-ci run 40104384896 (`pill-selftest` artifact). That run's self-test failed two timing checks on main (expand median, Reduce Motion expand) before this work started.
