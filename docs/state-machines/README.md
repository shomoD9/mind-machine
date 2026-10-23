# State machines

| File | What it holds |
| --- | --- |
| `product.md` | Statechart of Mind Machine as a person uses it, with states, events, guards, invariants and open decisions. |
| `software.md` | Statecharts of the code (vault store, indexer, search, CloudKit sync, App Group storage, Mac window), plus mismatches and dead ends. |
| `factory-pipeline.md` | The agent pipeline from spec to TestFlight, with the skill and gate at each step. |
| `charts/` | The Mermaid sources. `product.mmd` is the full chart. `check-*.mmd` are the slices that `statechart from-chart` verifies. |

Formal model of sync and the shared vault: `spec/MindMachineSync.tla`, run with `spec/run-tlc.sh`. Bug tickets from it: `.scratch/state-machines/issues/`. Skill that runs it: `.agents/skills/verify-mindmachine-sync/SKILL.md`.

Skills used: `statechart` and `create-formal-verification-skill` (pstack by Lauren Tan, `cursor/plugins`, v0.15.30), `software-factory` (Matt Pocock, PR #1316).
