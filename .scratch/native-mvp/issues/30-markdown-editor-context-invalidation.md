# 30: Markdown editor ticket 3 — context invalidation

Status: claimed
Blocked by: none (ticket 26 styles merged in PR #12)

Implement ticket 3 from `/workspace/research/markdown-editor.md` in the `md-context-invalidation` worktree. Ticket 27 is capture speed; 28 is reserved for concurrent editing commands. Origin branches checked before claiming 29.

- [ ] Portable invalidation includes both sides of newline splits/joins and reclassifies indentation changes for the existing parser subset.
- [ ] Deterministic adversarial/random edit oracle compares applied incremental styles with full parsing and literal Unicode source bytes.
- [ ] Ordinary typing touches only its paragraph; preserve the 8,192 UTF-16 affected-span cap and native oversized fallback.
- [ ] Keep AppKit integration additive, synchronous and small; document unsupported fence/reference context and impossibility of stale asynchronous parsing.
- [ ] Record before/after evidence, run portable/native checks without changing timing budgets, update design/journal, push one PR and leave unmerged.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-mdctx): read the complete research, AGENTS, CONTEXT, docs/agents, DESIGN, privacy ADR and tickets 25/26. The current parser is line-local; fenced-block state, reference definitions and nested-container context are absent. A split ending with a newly inserted separator appears to omit its right paragraph from restyling. Tests will establish exact divergence before implementation. Cloud status tooling/network-policy snapshot unavailable; use configured gh without inspecting credentials.

- 2026-10-25, GPT-6 / Codex API (mm-mdctx): first PR #17 push 2171e99 passes Linux (39 tests), both app builds, both UI jobs and sandbox self-test. Both hosted SwiftPM lanes reject ordinary locality (`{8,13}` vs `{8,7}`), while the new attribute oracle passes. Read logs; record character edits before attribute repair via willProcessEditing so the invalidator receives the precise change. All existing tests and budgets retained. Second verification push pending.

- 2026-10-25, GPT-6 / Codex API (mm-mdctx): merged origin/main at 12f53bd after PR #15. Renumbered this ticket to 30 because Recall cards now owns 29 on main. Preserved both implementations and journal/design histories; rerunning Linux and hosted checks for the integration commit.
