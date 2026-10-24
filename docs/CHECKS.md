# Native checks

Run `native/Scripts/checks.sh` on a Mac with Xcode 26.2. It exits on the first failed gate, in this order. CI calls this exact script on macOS; no signing credentials are used.

| Gate | What it proves | Typical cost | When |
| --- | --- | --- | --- |
| Diff whitespace | No whitespace errors in the working diff. No Swift formatter/linter is configured. | <1 s | Every push/PR |
| Swift package tests, including Pill | Public saved-vault/workspace invariants, encrypted merge stories, 151-revision reversed batches, window retention, pill state/geometry. | 1–2 min cold build | Every push/PR |
| TLC + negative controls | All projection safety rules at 4 revisions/3 values with arbitrary delivery and a broken-delete control; protocol safety at 3 revisions/1 note/2 devices/3 processes; historical bugs and early acknowledgements still produce expected counterexamples. Swift tests replay real code separately. | ~40 s | Every push/PR |
| Release resources + durability | 10k-note query p95 <10 ms; append p95 <12 ms; acknowledged saves survive SIGKILL and concurrent writers; fresh core-process median snapshot <100 ms, first Recall <20 ms, append p95 <12 ms and peak RSS <16 MiB. | 1–2 min | Every push/PR |
| Compiled bundles + capabilities | iOS app embeds keyboard; all compiled IDs/resources match expectations; requested App Group, CloudKit, Keychain and Mac sandbox entitlements match compiled identifiers. | 2–5 min cold build | Every push/PR |
| Extended model bounds | All `spec/*.cfg`, including 4-revision safety and 3-revision fair convergence/crash liveness. Same invariants; larger exploration. | 15–120+ min | Nightly/manual `--extended` |

The budgets follow measured same-runner samples in `verification/overnight-perf.md`; they are macOS core-process regression guards. Real iPhone activation, jetsam headroom, host typing and signed two-device CloudKit delivery remain device acceptance gates. The entitlement check validates unsigned requests, not Apple provisioning or delivery. Existing `native-ci` separately retains unsigned native builds and the real Mac sandbox pill smoke test. `testflight.yml` is unchanged.

Install Java 17+ for TLC (CI provisions 21). Without Java the script prints an explicit skip; Swift regressions still run. `spec/run-tlc.sh` downloads the SHA-256-pinned TLC 1.7.4 jar. The nightly schedule becomes active after merge to main; use workflow dispatch with `extended_model=true` beforehand. Logs are uploaded as the `core-checks` artifact. For a same-runner before/after comparison, run `native/Scripts/compare_core_performance.sh 7ac950e`.
