# Linux core lane and job watchdog

Status: resolved
Blocked by: none

## Acceptance

- Measured Linux-compatible existing tests and documented exclusions; new isolated SHA-pinned fast-core workflow.
- Persisted watchdog transitions, dual-source silence detection, one relaunch, secret-free change events; stdlib tests.
- Local verification, PR to main, all three workflows green, /tmp/mm-fast-result.md handoff. No merge.

## Comments

- 2026-10-24 GPT-6 / Codex API (mm-fast): read mandated checks, domain/ADR/tracker guidance; claimed the two founder-authorized deliverables. Full package imports Apple-only frameworks. Installing official Swift 6.2.1 to measure a manifest-selected portable subset.

- Acceptance evidence/review: PR https://github.com/shomoD9/mind-machine/pull/7 at fd09149 has green native-ci (40084153615, all five jobs), fast-core (40084153643, 51s) and core-checks (40084153736 attempt 2). First core attempt failed the existing append budget; unchanged code/thresholds pass the fresh-runner rerun (3.982ms median). Docs retain both results. Linux local 23 tests/cold 8.377s; hosted core build/test 9s vs same-commit Mac package job 120s/Debug step 17s. 17 watchdog tests plus real child/zombie and detached-single-relaunch smoke pass; no secret output. Reviewed final diff for prohibited paths and Apple behavior preservation. Final privacy/timing checkpoint receives another hosted verification before /tmp/mm-fast-result.md is written; no merge.

- Relaunch 1 evidence: resumed from 5c51db2 and ran Linux first (23 tests, 1.759s warm) plus 17 watchdog tests. Compared Apple-selected manifest dump-package JSON and guard-resolved cipher with main: identical. Inspected retained xcresult: empty-query predicate expired while its AX query was interrupted, later editor empty. Only failed simulator job reran unchanged in native-ci 40085569546 attempt 2: 3/3 journeys pass, zero failures/301.589s; all five jobs green. fast-core 40085569576 green (62s job/8s core); core-checks 40085569686 attempt 2 green (append 2.966ms vs initial 21.406ms, same 12ms budget). Documented timing failures without changing UI, test driver, production storage, limits or existing workflows. Publishing documentation-only checkpoint, then verifying final PR checks and writing requested result file; PR remains unmerged.

- 2026-10-24 PR #7 conflict-repair continuation: merged origin/main 5585afd after PR #8. Preserved every line of both parents in DESIGN and the journal; incoming schema files match main. All 17 Python watchdog tests pass. No app/workflow edits; pushing the merge and monitoring Linux/Mac PR checks for up to 40 minutes. Final evidence: /tmp/mm-fast-rebase-result.md; no PR merge authorized.
