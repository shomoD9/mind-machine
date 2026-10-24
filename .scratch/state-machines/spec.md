# State machines and formal verification

Product and software statecharts live in `docs/state-machines/`. The TLA+ model of sync and the shared vault lives in `spec/` and runs with `spec/run-tlc.sh`. The tickets in `issues/` are the counterexamples TLC found against origin/main `c45031b`, plus one umbrella ticket for the chart/code mismatches.

Tickets here describe behaviour to fix. None of them changes code yet. Each lists the TLC configs that must flip from `violation` to `pass` as acceptance evidence, using the proposed-fix configs `spec/fixed-*.cfg` as the design to test against.

Related: [product chart](../../docs/state-machines/product.md), [software chart](../../docs/state-machines/software.md), [verify skill](../../.agents/skills/verify-mindmachine-sync/SKILL.md).
