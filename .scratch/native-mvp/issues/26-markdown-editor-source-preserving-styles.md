# 26: Markdown editor ticket 2 — source-preserving live styles

Status: claimed
Blocked by: none (ticket 25 baseline merged in PR #11)

Implement ticket 2 from `/workspace/research/markdown-editor.md`. Ticket 24 / PR #10 owns Capture layout. Keep this change in parsing, Mac text handling and verification.

- [ ] Headings `# ` / `## ` / `### `, bullets, unchecked/checked tasks, bold, italic and inline links style as typed, with visible muted markers.
- [ ] Copy/save/reopen preserves literal UTF-8 source, including emoji and combining marks.
- [ ] Ordinary edits restyle only their paragraph; TextKit 2 stays active; composition and native selection/undo survive.
- [ ] Portable parser tests and Mac adapter/round-trip checks pass; rerun ticket 1 timing and compare before/after.
- [ ] Commit, push, open the requested PR against main, watch every check, leave unmerged and write `/tmp/mm-mdstyles-result.md`.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): read research, repository/domain/tracker/triage guidance, CONTEXT and ADR. Fetched main and pill-capture-redesign; highest numbers are 25 and 24, so claimed 26. Requested a fresh unchanged-main native-ci baseline run (40153281833); retained merged-main run 40150896097 as an additional comparison. Linux has Swift under `/tmp/mm-swift` and no AppKit; hosted Mac CI supplies runtime evidence. No cloud-status tool or network-policy file is available; configured GitHub CLI works without inspecting credentials.
