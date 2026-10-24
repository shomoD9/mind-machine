# Factory phase 1

Phase 1 labels PRs and closes rejected ones. It runs on Linux and uses **zero AI tokens per PR**. It never merges. A PASS is only an intake result; only evidence may merge. Native build/test evidence remains in [CHECKS.md](CHECKS.md).

| Lane | Paths and behavior |
| --- | --- |
| A | Markdown/docs, translations and tests-only changes. PASS intake. |
| B | Core package logic and other paths without a stricter rule. ROUTE for review. |
| C | Sync, storage, workspace/pill state and `spec/`. ROUTE; approved spec is a future prerequisite, with no approval flow or auto-merge here. |
| D | `.github/`, `factory/`, agent configuration, dependencies, entitlements, Info.plist, Xcode/config/build/signing scripts and keyboard source. Reject outsiders. |

`factory/lanes.json` holds the rules. All matching rules apply; the strictest lane wins, including both paths of renames and deleted paths. Paths are normalized before matching. Keyboard source is conservatively D because a path alone cannot establish whether an edit enables networking. Added/deleted API patch lines mentioning network APIs or Full Access also enter D, including shared code; missing Swift/plist patches enter D. These checks are conservative routing rules, not semantic proof against obfuscated network code.

The default budget is **1,000 additions + deletions and 100 files** per PR, configurable in `lanes.json`. Outsiders must link an issue in the body with `Refs #123`, `Fixes #123` or a full issue URL in this repository. This checks the reference syntax, not issue approval or acceptance criteria. OWNER/MEMBER/COLLABORATOR associations and exact factory bot logins with GitHub's Bot type bypass outsider-only rules; they still receive a lane and obey budgets. The only configured bot is `github-actions[bot]`. There is no vouch policy.

| REJECT code | Next step |
| --- | --- |
| `LANE_D_OUTSIDER` | Ask a maintainer to make the protected change in a trusted branch. |
| `SIZE_LIMIT` | Split the PR to fit both configured budgets. |
| `ISSUE_REQUIRED` | Add a repository issue reference; submit a new PR. |
| `INVALID_PATH` | Remove absolute paths, repository escapes or backslashes. |
| `FILES_INCOMPLETE` | Reduce the file count so every path can be checked. GitHub exposes at most 3,000 PR files. |

`pr-intake` uses `pull_request`, read-only contents permission and the immutable **base commit's** factory files. No PR head is checked out or executed. API calls use argument arrays; title, body and branch text stay data. It uploads one JSON artifact even for REJECT. `pr-gate` runs from the default branch on `workflow_run`, validates a closed schema and bounds, binds the result to the successful run, current head/base, metadata and fork repository/branch, then labels or comments/closes. It reads the producer workflow through the API and requires head/base copies to equal the trusted copy: a PR that edits the producer cannot forge an accepted result. Such results and stale/malformed artifacts fail closed for maintainer review; they never authorize writes. Factory script edits are still judged with base scripts. The gate needs actions:read to download the artifact; PR/issues writes exist only in that job. It never runs artifact contents or restores PR caches.

First installation needs maintainer review: the base branch has no factory scripts yet, and `workflow_run` consumers become active only on the default branch. This PR cannot demonstrate a live close before installation. After installation, ordinary `factory/` changes use the installed base classifier. Existing native workflows still run PR builds separately with read-only tokens; the zero-code guarantee applies to intake and gate, not those test jobs. TestFlight signing and secrets logic is preserved.

All remote actions use commit pins. `check_workflows.py` is the second fixed-order gate in `checks.sh`, followed in the same gate by the stdlib factory suite. The source guard requires top-level permissions, forbids floating action refs and forbids `pull_request_target` entirely in this repository. Full Actions/YAML syntax is verified with actionlint during development.

To add a lane rule, add a `{ "lane": "C", "paths": ["real/path/*"] }` object in `lanes.json`, deriving paths from the tree. Patterns use Python `fnmatchcase` on normalized repository paths (`*` includes `/`). Add a fixture naming the rule it guards, then run `python3 -m unittest discover -s factory` and `python3 factory/check_workflows.py`. Change rules in a maintainer PR: outsiders cannot change their judge. Review checks that have not fired in 90 days for removal.

Spec approval ownership, whether outside lane C code may merge directly, vouch policy, AI model/token caps, a permanent keyboard-network policy, and dead-code tooling remain open decisions from the plan. No AI/LLM tier, vouch automation, spec approval, PR-limit policy, lane C auto-merge or rewrite factory is built. Those decisions need explicit agreement; no phase 1 verdict supplies it.
