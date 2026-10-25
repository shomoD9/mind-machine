# 30: Markdown editor ticket 5 — capture handoff

Status: claimed
Blocked by: none; publishing and hosted verification resumed with authorization for up to two additional pushes

- Preserve final source characters across rapid typing and close/reopen.
- Copy Markdown source to the clipboard.
- Keep delayed capture storage off the input path; preserve newer drafts on acknowledgement/failure.
- Test portable handoff logic first on Linux and the thin real AppKit adapter on Mac.
- Record before/after latency and runtime evidence in docs/verification/markdown-capture-handoff/README.md.
- Commit, push at most three rounds, open the requested PR, poll checks, do not merge.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-handoff): claimed within the user-specified worktree and behavior-only scope. Public test seams are the portable capture handoff and actual Mac editor/model. Existing tests and budgets stay intact.

- 2026-10-25, GPT-6 / Codex API (mm-handoff): implementation and manual spec/standards review complete. All eight hosted checks pass at `61bbb91` on PR #18, including 73 Mac package tests (one existing skip), five native handoff tests and both UI journeys. Evidence, raw before/two after latency runs and failing-first portable assertions are in `docs/verification/markdown-capture-handoff/README.md`. The third push records evidence only and is checked separately; PR stays open and unmerged.

- Final publication: `4e295e8` has passing fast-core only; native checks are absent because main advanced to `12f53bd` and the agent journal conflicts. Both journal sections and the application changes have been retained in a local merge, verified on Linux and with Swift parsing. The three-push cap prevents publishing it. PR #18 remains open and unmerged; needs a separately authorized additional push and native reverification.

- Resumed publication: the human authorized up to two further pushes, local portable/Linux tests and at most 45 minutes of hosted check polling. Fetched origin; latest main remains `12f53bd`, already contained in the local merge. Rechecked the journal resolution and additive application merge. Hosted verification remains pending; do not merge.
