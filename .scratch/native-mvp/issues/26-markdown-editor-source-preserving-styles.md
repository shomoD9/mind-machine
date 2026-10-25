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

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): fresh investigation from 4e39782 read failed native/core logs and PR diff first. Added bounded range discovery before parsing/enumeration, lazy attribute transactions and portable read-count/native-boundary tests; all 30 Linux tests pass. Mac regression and sandbox timing require hosted CI. Hold-delete failure is tracked separately. Maximum two push rounds, all protected files/tests/budgets retained.

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): fix2 investigates the repeated 100 KiB single-paragraph sandbox timeout in native-ci 40158812108. Added real AppKit attribute-transaction/bounded-work regression before changing the styler; hosted macOS supplies the runtime loop. Retained claimed status, deadline and all existing acceptance checks.

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): second-round core-checks 40158681570 still rejects the fixture's .string request. Third/final round uses AppKit's advertised writablePasteboardTypes for native copy negotiation and retains the same plain-string byte equality. No production behavior or scope changes.

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): f80e5e1 clears compilation; Mac UI acceptance passes. Core-checks 40158491867 exposes the copy fixture's missing pasteboard type declaration. Switched its native selection write to the declaring multi-type API per Apple documentation; retained byte assertions and all production behavior. Local syntax/whitespace checks and 28 portable tests passed; second hosted round pending.

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): resumed PR #12 at dcd638b; failed CI logs confirm an unavailable nested AppKit edit-actions type and ambiguous NSSize constants. Corrected the signature to NSTextStorageEditActions and qualified CGFloat constants without changing parsing, source handling, layout values or ticket scope. Hosted CI verification pending.

- 2026-10-25, GPT-6 / Codex API (mm-mdstyles): read research, repository/domain/tracker/triage guidance, CONTEXT and ADR. Fetched main and pill-capture-redesign; highest numbers are 25 and 24, so claimed 26. Requested a fresh unchanged-main native-ci baseline run (40153281833); retained merged-main run 40150896097 as an additional comparison. Linux has Swift under `/tmp/mm-swift` and no AppKit; hosted Mac CI supplies runtime evidence. No cloud-status tool or network-policy file is available; configured GitHub CLI works without inspecting credentials.
