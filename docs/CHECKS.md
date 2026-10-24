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

## Linux fast feedback

`.github/workflows/fast-core.yml` runs on every push and PR on `ubuntu-latest` in `swift:6.2.1-noble`. It installs SQLite headers (`CSQLite` resolves `sqlite3` through pkg-config), runs `swift test --package-path native --jobs 2`, and runs the stdlib watchdog tests. Checkout is pinned to the full commit obtained with `gh api repos/actions/checkout/git/ref/tags/v4`. The job prints `MM_LINUX_CORE seconds=...` and puts build/test elapsed time in the job summary; a five-minute timeout bounds runner use. There is no model call or build cache. The target is roughly 2–3 minutes to feedback including container setup.

On Linux the manifest builds the actual `Vault`, `VaultFile`, `NoteRevision`, `KeyboardWorkspace`, and portable `SyncFailure` definitions. The existing `VaultTests`, `IndexedVaultTests`, `KeyboardWorkspaceTests`, and `SyncInvariantTests` run unchanged: **23 tests** for persistence/migration, Recall prefix/typo/highlights, task/reminder boundaries, draft preservation, transaction rollback, and concurrent/out-of-order revision projection, including the 151-revision reversed batches. Only the CryptoKit cipher declaration is conditionally compiled; Apple code and all Apple package targets retain their behavior.

Linux exclusions (all retained in macOS CI):

| Excluded | Reason / remaining authority |
| --- | --- |
| `PrivateCloudSync`, `PrivateSyncKey`, `RevisionCipher` encryption and `ReplicationTests` | CloudKit, Security/Keychain and CryptoKit. Plaintext projection stories still run on Linux; encrypted round trips and account-binding tests run on Mac. |
| `ProcessMemory`, `VaultIntegrityProbe`, `SearchPerformanceTests` | Darwin/os process APIs and Mac-specific resource budgets. Release search/save, RSS and crash/concurrent-process durability stay on Mac. |
| `MindMachineUI`, `MindMachineUITests` | SwiftUI, UserNotifications and platform editors. No UI logic was moved or stubbed for this lane. |
| `native/Pill` | Actual Linux attempt fails at `import CoreGraphics` in geometry. Keep the whole existing 35-test package on Mac rather than add a geometry substitute. |

Measured on 2026-10-24: the official Swift 6.2.1 Ubuntu 24.04 toolchain installed on this Debian x86_64 box passed the 23 tests with a cold build in **8.377 s** (test execution **0.946 s**). The original full package fails with `no such module 'CloudKit'`; Pill fails with `no such module 'CoreGraphics'`. These are compile attempts, not inferred compatibility claims.

For a measured Mac comparison, [main native-ci run 40082774512](https://github.com/shomoD9/mind-machine/actions/runs/40082774512) at `8fa4c3d` completed its package job in **151 s**; its Debug `swift test` step took **25 s**, and Pill took **19 s**. That job also includes Release benchmarks, process durability and the MiniSearch comparison, so it does more work. Local time excludes toolchain installation; hosted fast-core time includes image/dependency setup.

`native-ci` and `core-checks` remain the authority for the full Apple package, resource budgets, TLC and native apps. The fast lane adds earlier portable failures without removing any gate.

PR #7 measurements at `fd09149` ([Linux run](https://github.com/shomoD9/mind-machine/actions/runs/40084153643), [Mac run](https://github.com/shomoD9/mind-machine/actions/runs/40084153615)):

| Measured scope | Linux fast-core | Mac package job |
| --- | --- | --- |
| Entire job, excluding queue | **51 s** | **120 s** |
| Debug core build/test step | **9 s**, cold build, 23 tests | **17 s**, full Apple package |
| Additional work | 16 watchdog tests in 0.200 s | Release budgets, durability, MiniSearch comparison, Pill (24 s) |

Linux container initialization took 26 s and dependencies took 9 s. This measured lane beats the 2–3 minute feedback goal while retaining the narrower coverage listed above. The privacy checkpoint `ba972a3` also passed: [fast-core 40085392194](https://github.com/shomoD9/mind-machine/actions/runs/40085392194) took 56 s total / 12 s core build+tests, with all 23 Swift tests and 17 watchdog tests green. No Swift code changed after the initial measurement.


The first core-checks attempt at this commit failed the unchanged 12 ms fresh-process append budget (median 26.657 ms; samples 31.402/26.657/5.033 ms). [Attempt 2](https://github.com/shomoD9/mind-machine/actions/runs/40084153736/attempts/2) passed the same code and thresholds on a fresh runner: append median 3.982 ms, cold snapshot 9.949 ms, first Recall 4.441 ms, peak RSS 10.594 MiB. The first failure remains recorded; no gate or production storage code was changed.
