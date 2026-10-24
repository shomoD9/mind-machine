# Overnight core performance — 24 October 2026

Three fresh-process samples per version on the same macOS CI runner, identical closed 10k-note SQLite bytes and identical public-API probe instrumentation. Baseline: `7ac950e`; optimized: `c4aa3e0`. No real iPhone extension numbers are claimed. File-system cache state is not controlled.

| Metric (median of three samples) | Before | After |
| --- | ---: | ---: |
| Cold process open + 100-source snapshot | 8.354 ms | 8.499 ms |
| First Recall after snapshot (`teles`) | 3.934 ms | 3.729 ms |
| Durable append p95 (100 saves per process) | 8.233 ms | 3.484 ms |
| Peak core-process RSS | 12.078 MiB | 10.578 MiB |
| Physical footprint after saves | 3.220 MiB | 3.173 MiB |

Append p95 fell 58%; peak RSS fell 12%. Cold snapshot time was unchanged within noise. First Recall improved slightly; the sample is too small for a general latency claim. A preceding slower-runner comparison also showed lower append p95 (14.221→5.697 ms) and RSS (12.109→10.609 MiB), but its first-process cold-open variance was large. The cache reduction lowers RSS more than physical footprint.

The existing Release benchmark reported warm query p95 **6.477→4.581 ms**, durable append p95 **16.637→3.401 ms**, and cold open plus first query **23.688→16.301 ms** in separate baseline/final jobs; runner variation prevents attributing the whole difference to code. The query budget remains 10 ms. Append p95 is now gated at 12 ms. Dedicated fresh-process median budgets are snapshot 100 ms, first Recall 20 ms, append p95 12 ms and peak RSS 16 MiB; they include room for shared-runner variance and are not iPhone memory limits.

Evidence: [baseline red + benchmark](https://github.com/shomoD9/mind-machine/actions/runs/40023094767), [same-runner comparison](https://github.com/shomoD9/mind-machine/actions/runs/40055107047), [final Release package job](https://github.com/shomoD9/mind-machine/actions/runs/40055110970/job/120756281318). The comparison also runs the new window regression against the old model and checks its specific failure: `Save must keep the newest older source`.

Reproduce: `native/Scripts/compare_core_performance.sh 7ac950e`. Production changes avoid unindexed FTS delete scans, bound checklist reads/results, use indexed snapshot ordering, lower SQLite page cache from 2 MiB to 512 KiB and optimize common two-letter prefixes. An attempted one-letter correlated query was measured slower and reverted before the final measurements. Corpus dates are explicit so the newest-source assertion does not depend on equal clock timestamps/random UUID ordering. Mac pill opening, actual keyboard activation, host typing and iPhone jetsam headroom still need their respective native/device acceptance runs.
