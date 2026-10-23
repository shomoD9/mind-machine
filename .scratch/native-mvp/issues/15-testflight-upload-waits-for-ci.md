# 15: TestFlight uploads wait for native CI, and timing checks stop flaking

Status: needs-info
Blocked by: founder decision on release gating

**What to build:** A push to main uploads a build only after the unsigned native CI run for that commit passes, so a build never ships from a commit that failed tests.

The upload workflow currently triggers on any push touching the native folder, independent of the test workflow. Separately, the pill animation self-test and the 10 ms p95 search assertion depend on shared-runner timing and have failed on unchanged code (native-ci run 39915353925 failed twice on animation timing).

- [ ] Founder chooses: upload after CI success, manual only, or keep as is
- [ ] If gated, a failing CI run produces no upload
- [ ] Timing checks use repeated samples or a retry so one slow runner does not fail the run
