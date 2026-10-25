# 31: Markdown editor ticket 6 — bounded preview comparison

Status: claimed
Blocked by: none for a rejection comparison; accepting hiding additionally requires research tickets 3/5 and every native/hardware gate

Compare the muted-marker editor on main with one small, test-only marker-hiding equivalent. Source: `/workspace/research/markdown-editor.md`, especially ticket 6 and Speed gates and measurement. Stop at a demonstrated rejection; retain muted markers unless every gate passes. The user explicitly authorized this bounded comparison while context invalidation and capture handoff remain separate branches.

- [ ] Inspect a pinned reference and its licence; introduce no package dependency.
- [ ] Compare source, selection, undo, caret geometry and wrapping using the real TextKit 2 editor.
- [ ] Record paired before/after timing distributions and the boundary of each observation; explicitly identify unmeasured VoiceOver and hardware gates.
- [ ] Keep production muted markers when any acceptance gate fails or remains unproven.
- [ ] Update DESIGN/journal, open the requested PR with evidence, watch hosted checks, leave unmerged and write `/tmp/mm-preview-result.md`.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-preview): read research first, then repository/domain/tracker/triage guidance, CONTEXT, privacy ADR, DESIGN/editor verification and current editor/tests/workflows. Fetched origin and scanned remote tracker files: 29 is used by context invalidation/Recall and 30 by capture handoff; reserved 31. Linux has Swift 6.2.1 but no AppKit. Hosted Mac SwiftPM supplies the native experiment; Release M1 Air/macOS 14/current-OS, physical pixels and VoiceOver remain explicit acceptance requirements. Checked NoteKit at `8b2c446413d98b5180d52ab35f1a919398e48a7f`: MIT, no external package dependencies, collapsed marker fonts and delayed click reveal. Testing an independently written equivalent avoids adopting its unrelated editor/session features.
