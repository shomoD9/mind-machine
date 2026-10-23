# State models

`product.md` and `software.md` carry PR #2's charts and historical audit. The current core behavior is recorded at the top of software.md. Mermaid sources live in charts/.

`spec/run-tlc.sh ci-safe` checks all current safety rules at three revisions on pushes. `spec/run-tlc.sh` checks all historical counterexamples, four-revision safety and three-revision convergence in the extended manual/nightly gate. The full model is not Swift verification; SyncInvariantTests replay its counterexamples and the 100-record batch boundary through the shipped store.

These files were selectively read/copied from PR #2; that branch was not merged. See PR #2 for its statechart and verify-mindmachine-sync skills. No software-factory infrastructure is introduced.
