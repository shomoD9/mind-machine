# 32: Markdown editor ticket 7 — iPhone app adapter

Status: claimed
Blocked by: none; research tickets 2–5 are merged in main

- Use UITextView/TextKit 2 in the companion with shared portable source/range/block/command logic.
- Preserve exact plain Markdown bytes, emoji, combining marks, selection, marked text and undo.
- Continue/exit lists and tasks; keep the keyboard extension's behavior and dependencies unchanged.
- Add Simulator evidence through the existing native-ci host, sample typing against unchanged research budgets, and run Linux core tests.
- Keep UI minimal, protected paths untouched, publish one PR with at most three pushes, watch checks and do not merge.
- List physical iOS17/TestFlight checks for Shomo; write `/tmp/mm-iphone-result.md`.

## Comments

- 2026-10-26, GPT-6 / Codex API (mm-iphone): read research item 7, DESIGN, merged parser/invalidation/commands/handoff, project/domain/tracker/triage guidance and privacy ADR. Claimed ticket 32. UIKit presentation reuses the current bounded parser subset; no parser expansion or background jobs. Linux has no Apple SDK; the existing hosted Simulator job will execute the production adapter harness.
