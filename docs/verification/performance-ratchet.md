# Performance ratchet

Existing gates fail when `measured > main * 1.25 + absoluteMargin`, independently of their existing fixed budgets. Equality passes. Every expected metric must be positive, finite and present. No timing retries or environment switch bypass the ratchet. `MM_RATCHET` diagnostics show the observation, baseline and ceiling.

The committed baseline is [PerformanceBaseline.swift](../../native/Sources/MindMachineCore/PerformanceBaseline.swift). It is compiled into the shared package, including the sandboxed Mac self-test, so comparison needs no network, checkout-file access or workflow change. It references a recorded main commit. Improvements keep that reference until an explicit refresh; tolerated slowdowns cannot compound through automatic baseline updates.

| Existing gate | Measurements | Absolute allowance |
| --- | --- | --- |
| Release `SearchPerformanceTests` (native-ci and core-checks) | Aggregate Recall query p95; all 11 `MM_QUERY` p95s | 0.75 ms aggregate; 1 ms per query (1.5 ms for `p`, 0.5 ms for the three sub-ms queries) |
| Same Release test | Durable save p95 | 2 ms |
| `checks.sh` gate 4, `VaultIntegrityProbe ratchet-keyboard` | Median of three fresh-process cold snapshots / first Recall / append p95 / peak RSS | 3 ms / 2 ms / 2 ms / 1 MiB |
| Mac `PillSelfTest` (native-ci mac-build) | Recall dispatch / typed-letter draw / cards-drawn p95 over its existing 48 keys | 2 ms / 5 ms / 10 ms |

Percentile definitions and sample counts are unchanged. Keyboard append uses the median of three 100-save p95s; snapshot, first Recall and RSS use the existing process medians. All three records must contain valid values before reduction. Keyboard memory remains fresh-process `peak_rss_mib`; whole-test-process RSS and diagnostic physical footprint are excluded. Mac draw timings remain proxies, not hardware key-to-pixel measurements. Capture typing fixtures are unchanged; this ticket covers Recall typing.

The 25% relative allowance accommodates VM speed variation. Absolute allowances keep sub-ms operations and SQLite flush jitter from becoming percentage-only failures. Cold snapshot includes process/database startup, so its floor is larger. These are detection limits, not claims that every slowdown is distinguishable from runner noise. Fixed query/save, keyboard and Mac timing caps remain unchanged and can be stricter than a ratchet ceiling.

## Baseline provenance

Main commit `e556df507da4902afdb58e6953a974dc0980b650`, macOS 26, Xcode 26.2:

- [native-ci 40216843098](https://github.com/shomoD9/mind-machine/actions/runs/40216843098): `search-benchmark/search-benchmark.txt` contains aggregate/per-query/save p95s; `pill-selftest/result.json` contains `recallCardsTyping` distributions and raw samples. Both benchmark and sandbox self-test passed.
- [core-checks 40216843122](https://github.com/shomoD9/mind-machine/actions/runs/40216843122): `core-checks.txt` contains three `MM_KEYBOARD_CORE` records and `MM_CORE_BUDGET` medians.

Preceding main `12f53bd` ([native-ci 40211764426](https://github.com/shomoD9/mind-machine/actions/runs/40211764426), [core-checks 40211764492](https://github.com/shomoD9/mind-machine/actions/runs/40211764492)) provides a variance cross-check: query/save p95 4.820/4.800 ms, keyboard snapshot/first Recall/append/RSS medians 9.810 ms / 4.648 ms / 4.517 ms / 10.531 MiB. Recall letter/cards p95 was 14.352/35.433 ms versus current main's 32.388/70.703 ms. These independent jobs illustrate why a percentage-only threshold would be flaky. Historical results are not substituted for a faster baseline. Replaying the preceding core artifact initially rejected three per-query tails despite the aggregate passing: `p` 6.346 ms, typo 2.836 ms and no-hit 0.540 ms. The per-query floors above retain that independently observed variation (only about 22 observations per query). Both main search jobs and the preceding core/pill/process artifacts pass the final comparator.

## Refresh when a slowdown is intentional

1. Explain the intentional cost and affected metric in the PR. Keep the baseline for ordinary changes. A workload change needs an explicitly comparable reference.
2. Fetch main and record its exact SHA. Download successful `search-benchmark`, `pill-selftest` and `core-checks` artifacts with `gh run download RUN_ID -n ARTIFACT -D /tmp/mm-baseline/ARTIFACT`. Confirm provenance with `gh run view RUN_ID --json headSha,conclusion`. Retain raw artifacts/run links and inspect multiple independent hosted samples; do not select a favorable retry or use local Linux timings.
3. Read aggregate/per-query/save p95s from `MM_BENCH`/`MM_QUERY`, three-process medians from `MM_CORE_BUDGET`, and `recallCardsTyping.{dispatch,dispatchToDrawProxy,dispatchToCardsDrawn}.p95Ms` from `result.json`.
4. Edit the affected `Metric(main: ...)` values in `PerformanceBaseline.swift`, and update its SHA/run comments and this provenance. If the intentional slowdown is still on a branch, its exception must explicitly identify the candidate SHA/runs and obtain baseline review in that PR; do not label candidate measurements as main. Relabel the reference with main's resulting SHA/artifacts after merge. Keep margins and all fixed budgets; changing a margin requires separate noise evidence. There is no automatic ratchet disable or baseline writer.
5. Run `swift test --package-path native --filter PerformanceRatchetTests` (portable). Update the below-fixed-budget negative-control examples if the intentional baseline moves their ceiling. On a Mac, run `native/Scripts/checks.sh` and the usual native-ci Mac self-test. Confirm hosted `MM_RATCHET PASS` for every metric before accepting the refresh.

## Prove a deliberate regression

`swift test --package-path native --filter PerformanceRatchetTests` calls the actual gate with 6 ms query p95 and 7 ms save p95, separately. Both pass the existing 10/12 ms budgets; both throw `MM_RATCHET FAIL` against this baseline. Tests also drive each metric independently past its ceiling and check the inclusive noise boundary, missing/nonfinite data, and one versus two slow keyboard processes. They exercise comparisons on Linux without claiming Linux performance equivalence. Hosted macOS supplies the actual timing observations through the unchanged existing workloads.
