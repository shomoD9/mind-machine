# 31: Performance ratchet

Status: resolved
Blocked by: none

Fail existing CI gates on measurable slowdowns against committed hosted-main numbers. Cover Release Recall query/save p95 (including per-query tails), fresh-process cold snapshot/first Recall/append p95/peak RSS, and Mac Recall typing p95. Preserve every fixed budget and all protected paths.

- [x] Commit baseline provenance and noise-aware relative plus absolute margins.
- [x] Add comparisons inside existing test/script gates, with missing/invalid measurements failing closed.
- [x] Prove Linux tests pass and a deliberate regression below an existing fixed budget fails.
- [x] Document intentional baseline refresh, update DESIGN and journal, open one PR and observe hosted checks without merging.

## Comments

- 2026-10-26, GPT-6 / Codex API (mm-ratchet): PR #20 at ca001b2 passed all eight hosted checks: native-ci 40220928728 (all five jobs), core-checks 40220928544 and both fast-core events. Actual raw artifacts confirm query/save p95s 3.499/2.298 ms in core-checks and 4.026/2.337 ms in native-ci; all keyboard and Mac Recall ratchets pass. Local 53 Swift/17 watchdog tests pass; standalone comparator exits 1 for an injected 6 ms query despite the old 10 ms cap. Reviewed the final implementation and diff: every original fixed-budget statement is preserved, measurement counts/formulas are unchanged, protected-path diff is empty. Baseline refresh and noise calibration evidence are in docs/verification/performance-ratchet.md. Final evidence-only commit will be pushed and its checks watched; leave PR open and unmerged.

- 2026-10-25, GPT-6 / Codex API (mm-ratchet): read repository, tracker, triage and domain instructions, CONTEXT, privacy ADR, existing gates and benchmark emitters. Fetched main e556df5 and downloaded its native-ci search/pill artifacts plus preceding main's core/pill artifacts to measure runner variation. Using shared Swift comparison logic so existing Release tests, core-checks probe and sandbox self-test can gate without workflow edits.
