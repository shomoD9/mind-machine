# Software factory pipeline for Mind Machine

The pipeline is: spec → statechart → formal spec (TLC) → tests → implementation → code review → CI → TestFlight. Each step has one skill and one gate that blocks the next step. Steps 1, 2, 5 and 8 keep a human gate for now.

Vocabulary comes from `.agents/skills/software-factory/SKILL.md` (Matt Pocock, PR #1316 on `mattpocock/skills`, unmerged on 2026-10-23): task, trigger, run, runner, ticket tracker, ticket source, git host, orchestrator, observability platform.

## Self-questioning (grill-me style, answered from the repo)

1. **What does a factory fix for this team?** Three agents (Claude Code, Codex, Duck Bot) and one founder. Every run starts with nothing in memory. A factory writes the state into tickets and PRs so the next agent finds it. Today the state lives in chat and in `docs/_J-*.md`.
2. **Which services fill the slots?**

   | Slot | Product | Note |
   | --- | --- | --- |
   | Ticket tracker | Local Markdown in `.scratch/<feature>/issues/` (`docs/agents/issue-tracker.md`) | The skill prefers an off-the-shelf tracker. Keep the files while the founder is the only human; revisit when outside testers file bugs. |
   | Ticket source | The founder, plus `spec/run-tlc.sh` and CI failures later | A TLC counterexample becomes a ticket (see `.scratch/state-machines/issues/`). |
   | Git host | GitHub (`shomoD9/mind-machine`) | |
   | Orchestrator | Duck Bot | Needs to receive triggers, start runs and record queued, in-flight and finished runs. Open: where Duck Bot keeps that record. |
   | Runner | Linux box (agents, docs, TLC); GitHub `macos-26` runners (Swift build, tests, Mac self-test, TestFlight) | The Linux box has no Swift toolchain, so every Swift gate runs remotely. |
   | Observability platform | None: GitHub Actions run pages plus Duck Bot's log | Enough until runs fail often. |

3. **What triggers a run?** A commit to `main` or a PR that changes a ticket's `Status:` line, or a label on a GitHub PR. `Status: ready-for-agent` starts the implementer task. The founder writes that line by hand at first.
4. **What stops two runs doing the same work?** The claim rule already in `docs/agents/issue-tracker.md`: set `Status: claimed`, push, and start only if the push is accepted. Duck Bot holds one lock per ticket.
5. **Where does a human re-enter?** Spec approval, chart approval, `ready-for-human` tickets (signing, a real iPhone, live CloudKit between two devices), PR merge, TestFlight promotion.
6. **Which brakes exist?** Automated checks: `native-ci.yml` and `spec/run-tlc.sh`. Automated review: `code-review`. Human review: the founder reads every PR. Add one accelerator at a time (below).
7. **What must never run unattended?** Anything that needs hardware: keyboard memory and typing on a real iPhone, the Carbon hotkey, live two-device sync. Any edit to `docs/PRODUCT.md`. Any edit that weakens a TLC rule or an `expect:` line.
8. **How does the factory go wrong here?** An agent turns a red TLC run green by deleting the rule. Gate: changes to `spec/*.tla` and `spec/*.cfg` need a human reviewer, and an `expect:` line changes only in a ticket that names it.
9. **What caps a loop?** Three rework runs per PR, then the ticket goes to the founder.
10. **Still open for the founder:** Is Duck Bot's queue durable across restarts? Who owns the App Store Connect key and the Team ID (CI today says "No signing, TestFlight or secrets")? Should Codex or Claude Code review the other's PRs?

## The pipeline

| # | Step | Task and trigger | Skill that runs | Gate that blocks the next step |
| --- | --- | --- | --- | --- |
| 1 | Spec | Founder files an idea; an explore run drafts the spec | `grill-with-docs`, `domain-modeling`, `to-spec`, `to-tickets` | Founder sets `Status: ready-for-agent` on the tickets. |
| 2 | Statechart | Run starts when step 1 flips the status | `statechart` (`from-chart`); edits `docs/state-machines/product.md` and `software.md` | `from-chart` on each changed slice: no broken `%% never` rule and "draws the chart back unchanged"; founder reads the diff of the chart. |
| 3 | Formal spec | Starts only if the ticket touches sync, the shared vault or revisions (see the file table in `verify-mindmachine-sync`) | `verify-mindmachine-sync` (made by `create-formal-verification-skill`) | `spec/run-tlc.sh` prints `ok` for every config. A new violation or a changed `expect:` line stops the run. |
| 4 | Tests | Implementer run | `tdd` (red first) | The failing test is run on a `macos-26` runner and the run link is saved in the ticket before any implementation. |
| 5 | Implementation | Same run | `implement` or `implement-spec`, by Claude Code or Codex | `native-ci` jobs green: package tests, Pill tests, `mac-build` self-test, iOS simulator build, bundle verification. |
| 6 | Code review | New run on PR open, by the other model | `code-review` (standards and spec in parallel), `blast-radius` for sync changes | Zero open findings; a fail triggers rework, three fails go to the founder. Then the founder reads the PR and merges. |
| 7 | CI | PR and `main` | `.github/workflows/native-ci.yml` plus one new Linux job running `spec/run-tlc.sh` | All jobs green on the merge commit. |
| 8 | TestFlight | Founder labels a release ticket | A release task on a `macos-26` runner (archive, sign, upload) | Founder promotes the build after the real-device checks in `docs/TESTING-TONIGHT.md` (keyboard memory, typing, both-direction sync, offline relaunch). |

Notes:
- Step 7's Linux job is a proposal. `.github/` was outside this change's scope.
- Step 8 does not exist yet. It needs the Team ID in `Config/MindMachine.xcconfig`, signing secrets and an App Store Connect API key from the founder.
- After a merge, a `retro` run (throttled to one merged PR in ten) proposes changes to this pipeline and to `AGENTS.md`. `correct` handles repeated mistakes.

## Order of adoption (start slow)

1. Run steps 2 and 3 by hand on every sync or UI ticket (this change).
2. Add the Linux TLC job (brake: automated check).
3. Add the implementer task for tickets labelled `ready-for-agent`, one ticket per day, human review on every PR.
4. Add the review task by the other model; cap at three reworks.
5. Add the TestFlight task once signing exists.
6. Open the throttle only after a month of PRs where review finds nothing the checks missed.
