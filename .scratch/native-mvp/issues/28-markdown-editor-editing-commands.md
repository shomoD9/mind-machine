# 28: Markdown editor ticket 4 — editing commands

Status: claimed
Blocked by: none (ticket 26 styles merged; line commands do not require ticket 3's style invalidation)

Implement ticket 4 from `/workspace/research/markdown-editor.md` on `md-editing-commands`. Ticket 27 / PR #14 owns Capture speed; keep its editor changes additive.

- [x] Enter continues bullets, tasks (unchecked), and numbered lists at the same indent; empty items return to Plain.
- [x] Tab / Shift-Tab indent / outdent the caret's list/task line by two spaces, with native fallback elsewhere.
- [x] Cmd-Shift-Return toggles only a task marker's check character.
- [x] Commands use pure portable UTF-16 edit plans; one native undo restores each command; composition and arrow selection stay native.
- [x] Failing-first portable tests cover exact Unicode bytes, selections/carets, nesting and LF; hosted Mac tests cover actual undo and composition.
- [ ] Update DESIGN, journal and verification; push one PR, watch CI, leave unmerged, write `/tmp/mm-mdcmds-result.md`.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-mdcmds): read complete research, repository/domain/tracker/triage guidance, CONTEXT, ADR, DESIGN and tickets 25/26. Fetched origin and scanned ticket numbers across all remote branches; capture-speed owns 27, so claimed 28. Tests use the user-specified portable planner and actual AppKit text-view boundaries. Linux Swift 6.2.1 is installed; AppKit runtime requires hosted CI.

- 2026-10-25, GPT-6 / Codex API (mm-mdcmds): PR #16, first hosted round `3ac2cb3`. All 39 Linux tests pass; core-checks 40199148582 passes all gates (63 package tests, one pre-existing skip; 35 Pill tests), including command undo/redo and composition on AppKit. Native-ci 40199148608 passes both builds, sandbox and both UI jobs; only the unchanged append benchmark fails at 16.033708 ms versus 12 ms. Verification README records measured latency and remaining hardware limits. Second checkpoint removes redundant keyDown dispatch and verifies the shortcut through the window.
