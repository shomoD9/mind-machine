# 27: Capture window open speed and typing latency

Status: claimed
Blocked by: none

Performance only, on branch `capture-speed` from latest main. Keep behavior/layout identical; leave PRODUCT, workflows, signing, entitlements and release/TestFlight files untouched.

- [x] Reuse repeatable Mac open-to-input and per-key harness; retain actual baseline samples.
- [x] Identify measured bottlenecks, optimise only justified work, remeasure.
- [ ] Preserve input, native undo/composition, source bytes, layout and existing tests.
- [ ] Commit, push, open PR titled "Capture window: open speed and typing latency", watch checks (45-minute bound, at most 3 push rounds), leave unmerged.
- [ ] Write `/tmp/mm-speed-result.md` with status, PR, before/after, changes and CI.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-speed): read tracker/triage/domain instructions, CONTEXT and privacy ADR before implementation. Linux has no AppKit; downloaded latest-main native-ci 40180636797 self-test artifact and benchmark logs before editing. Baseline warm-open p95 74.368 ms; typing draw p95 9.677/4.354/8.758/71.433 ms for 1/10/100 KiB and 100 KiB single paragraph. First push measures show-request cost and comparison candidates before any production optimisation.

- 2026-10-25, GPT-6 / Codex API (mm-speed), resumed: both Swift failures are the new fixture's partial grapheme selection; retained complete-accent `{8,2}` correction. Initial Mac self-test missed one of 20 expansions; unchanged same-SHA job rerun 121164068885 passed all 20 and every check. Recorded before/measurement-only/production-after raw samples and limits in `docs/verification/capture-speed/`. After p95 open 42.298 ms; key-to-draw 3.715/4.149/9.020/72.679 ms. Whole-flow improvement is unproven because unchanged-host observations vary. Independent Standards/Spec reviews found no code correctness issue; final documentation corrections applied. All 30 portable tests, Swift syntax, byte correctness and whitespace checks pass. Third/final push will carry fixture correction plus actual-storage comparison timing; full final CI and outcome will be in PR #14 and `/tmp/mm-speed-result.md`, with no merge.
