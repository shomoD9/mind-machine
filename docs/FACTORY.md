# Factory phase 1

Phase 1 labels PRs and closes rejected ones on Linux. It uses **zero AI tokens per PR** and never merges. PASS clears intake only; only evidence may merge. Native evidence remains in [CHECKS.md](CHECKS.md).

| Lane | Paths and result |
| --- | --- |
| A | Docs/Markdown, translations, tests-only. PASS. |
| B | Package logic; fallback for unknown paths. ROUTE. |
| C | Sync, storage, workspace/pill state, `spec/`, tracked build specifications. ROUTE; spec approval is not implemented. |
| D | `.github/`, `factory/`, agent configuration, dependencies, entitlements, Info.plist, Xcode/config/build/signing scripts, keyboard source. Reject outsiders. |

`factory/lanes.json` holds the rules. All matches apply; strictest wins, including rename origins and deleted paths. Paths are normalized first. Keyboard source is conservatively D because paths cannot establish whether an edit enables networking. Network/Full Access API patch changes in shipping Swift/plist code also enter D; missing patches fail into D. Docs/tests may quote APIs. This is routing, not semantic proof against obfuscated code.

Default caps are **1,000 added + deleted lines and 100 files**, configurable in `lanes.json`. Outsiders must link a repository issue in the body: `Refs #123`, `Fixes #123` or its full issue URL. This checks syntax, not issue approval. OWNER/MEMBER/COLLABORATOR and exact configured Bot identities bypass outsider rules; budgets and lane labels still apply. The only factory bot configured is `github-actions[bot]`. There is no vouch policy.

| REJECT code | Next step |
| --- | --- |
| `LANE_D_OUTSIDER` | Ask a maintainer to make the protected change in a trusted branch. |
| `SIZE_LIMIT` | Split the PR to fit both budgets. |
| `ISSUE_REQUIRED` | Link a repository issue; submit a new PR. |
| `INVALID_PATH` | Remove repository escapes, absolute paths or backslashes. |
| `FILES_INCOMPLETE` | Reduce the file count so every path is visible. GitHub exposes at most 3,000 files. |

`pr-intake` uses `pull_request`, contents:read and the immutable **base commit's** factory files. It uploads JSON even for REJECT. No PR head is checked out or executed. API calls use argument arrays; all PR text stays data.

`pr-gate` runs from the default branch on `workflow_run`. It reads one bounded JSON artifact without extracting files, validates a closed schema, and binds it to the successful run, current head/base, metadata and source repository/branch. Producer workflow bytes at head/base must equal the trusted copy. Edited producers and stale/malformed results fail closed before writes; ordinary factory edits are judged by base scripts. Valid results receive a lane label; REJECT gets an exact-code comment and closure. Only this job gets PR/issues write permissions and actions:read for artifact download. It never runs artifact contents, restores PR caches or merges.

First installation needs maintainer review: the base has no factory scripts, and the consumer activates only on the default branch. Live label/close verification follows installation. Existing native workflows separately execute PR builds with read-only tokens. TestFlight signing and secrets logic is preserved.

Remote actions use commit pins. Gate 2 in `checks.sh` runs `check_workflows.py` and stdlib factory tests before Swift. The source guard requires top-level permissions, rejects floating actions and forbids `pull_request_target` entirely. Development verification also uses actionlint.

To add a rule, add `{ "lane": "C", "paths": ["real/path/*"] }` in `lanes.json`, deriving paths from the tree. Python `fnmatchcase` patterns match normalized paths; `*` includes `/`. Add a fixture naming its rule, then run `python3 -m unittest discover -s factory` and `python3 factory/check_workflows.py`. Rule changes need a maintainer PR. Review checks unused for 90 days for removal.

Spec approval ownership, direct outside lane C merges, vouch policy, AI model/token caps, permanent keyboard-network policy and dead-code tooling remain open. No AI tier, vouch automation, spec approval, PR-limit policy, lane C auto-merge or rewrite factory is built; those require explicit decisions.
