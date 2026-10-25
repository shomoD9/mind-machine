# 29: Markdown editor ticket 3 — context invalidation

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
