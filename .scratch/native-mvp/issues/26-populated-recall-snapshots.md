# 26: Populated Recall self-test snapshots

Status: needs-info
Blocked by: final authorized push still fails the sandbox self-test's accessibility observations; two-push limit exhausted

Capture the existing Mac Recall listing with clearly fake sample notes after the Capture redesign (PR #10), using only the isolated self-test and existing CI artifact upload.

- [x] Explain the current row preview, highlighting, date, task state, ordering and keyboard behavior from source.
- [x] Seed four sample captures only in the throwaway self-test vault; search for a clue matching three.
- [ ] Retain the empty snapshot and add populated Recall plus Open tasks snapshots through the existing cacheDisplay path.
- [ ] Verify the visible rows and persisted PNGs; push at most twice, open the requested PR, bound the CI wait and download the artifact.
- [x] Copy PNGs to `/workspace/recall-populated.png` and `/workspace/recall-populated-tasks.png`, and write `/tmp/mm-recallshot-result.md` with status and explanation.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-recallshot), final evidence: push 2 is `c5b9ac7`; native-ci 40175567269 completed within the bounded poll. Mac compilation passed, sandbox self-test failed the same three observations (67/70), and all four other native jobs passed. Downloaded the artifact and inspected the three-result PNG, then verified exact copies to both requested paths. The tasks PNG is identical with the switch off and is explicitly invalid filtered evidence. Wrote `STATUS: BLOCKED` and the full source-derived explanation to the requested result file; updated existing PR #13's evidence. No further push or merge. This final tracker/journal/design evidence is local because the authorized push budget is exhausted.

- 2026-10-25, GPT-6 / Codex API (mm-recallshot), resume: PR #13 exists at `8c91a30`. Native run 40173502398 compiled successfully; its sandbox self-test failed three protocol-only accessibility checks although the downloaded PNG shows all three results. Added legacy attribute/action traversal and retained virtual-node identities in the self-test; preserved the assertions. This is push round 2 of 2. CI and final artifact/result-file verification remain pending, with a 30-minute polling bound and no further pushes authorized.

- 2026-10-25, GPT-6 / Codex API (mm-recallshot): read project/domain/tracker/triage guidance, CONTEXT, ADR 0001, DESIGN and the existing redesign evidence. Confirmed main includes PRs #10/#11 and the worktree is clean. The Mac entry point already creates a UUID temporary vault with sync and notifications disabled. Source inspection confirms results use a three-line start-of-note preview, bold matches and creation date; no dedicated title or keyboard result navigator exists. Linux has Swift 6.2.1 but no AppKit, so the existing native-ci Mac artifact is the runtime proof. Protected files and product behavior remain outside scope.
