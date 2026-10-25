# 31: Performance ratchet

Status: claimed
Blocked by: none

Fail existing CI gates on measurable slowdowns against committed hosted-main numbers. Cover Release Recall query/save p95 (including per-query tails), fresh-process cold snapshot/first Recall/append p95/peak RSS, and Mac Recall typing p95. Preserve every fixed budget and all protected paths.

- [ ] Commit baseline provenance and noise-aware relative plus absolute margins.
- [ ] Add comparisons inside existing test/script gates, with missing/invalid measurements failing closed.
- [ ] Prove Linux tests pass and a deliberate regression below an existing fixed budget fails.
- [ ] Document intentional baseline refresh, update DESIGN and journal, open one PR and observe hosted checks without merging.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-ratchet): read repository, tracker, triage and domain instructions, CONTEXT, privacy ADR, existing gates and benchmark emitters. Fetched main e556df5 and downloaded its native-ci search/pill artifacts plus preceding main's core/pill artifacts to measure runner variation. Using shared Swift comparison logic so existing Release tests, core-checks probe and sandbox self-test can gate without workflow edits.
