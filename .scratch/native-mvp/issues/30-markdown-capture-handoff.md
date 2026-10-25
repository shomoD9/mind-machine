# 30: Markdown editor ticket 5 — capture handoff

Status: claimed
Blocked by: none (styles, editing commands and Capture speed are on main; context invalidation PR #17 remains open and is independent of handoff)

- Preserve final source characters across rapid typing and close/reopen.
- Copy Markdown source to the clipboard.
- Keep delayed capture storage off the input path; preserve newer drafts on acknowledgement/failure.
- Test portable handoff logic first on Linux and the thin real AppKit adapter on Mac.
- Record before/after latency and runtime evidence in docs/verification/markdown-capture-handoff/README.md.
- Commit, push at most three rounds, open the requested PR, poll checks, do not merge.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-handoff): claimed within the user-specified worktree and behavior-only scope. Public test seams are the portable capture handoff and actual Mac editor/model. Existing tests and budgets stay intact.
