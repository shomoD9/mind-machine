# 25: Markdown editor ticket 1 — native baseline + timing

Status: claimed
Blocked by: none

Measure the existing Mac Capture surface before Markdown implementation. Source: `/workspace/research/markdown-editor.md`, Recommendation, Architecture, Speed gates and measurement, ticket 1. Ticket 24 on `origin/pill-capture-redesign` owns the layout; this ticket leaves layout, styling and editing behavior unchanged.

- [ ] Repeat open → visible/focused/input-accepting checks, typing immediately without a focus repair.
- [ ] Record raw samples and nearest-rank p50/p95/p99 against the proposed warm-open and typing budgets; distinguish draw completion from pixels displayed and total dispatch from custom processing.
- [ ] Exercise 1/10/100 KiB documents, a huge paragraph and a 1 MiB insertion; check exact synthetic text and TextKit 2 before/after edits.
- [ ] Keep the existing Mac CI self-test/artifact path; provide a Release rerun with 30 terminated-process opens.
- [ ] Review scope, commit/push, open the requested PR, watch all checks and record actual measurements and limitations.

## Comments

- 2026-10-25, GPT-6 / Codex API (mm-mdbase): read repository/domain/tracker/triage guidance and research; fetched both branches. Highest ticket on main is 23 and on pill-capture-redesign is 24, so claimed 25. Local executor is Linux without Swift/AppKit; hosted Mac CI is the runtime verification path. Budgets remain proposed observations, rather than a reason to change the editor in this ticket.

- 2026-10-25, GPT-6 / Codex API (mm-mdbase): first hosted run `40131868749` compiled and passed all other native jobs. The sandbox self-test hit its existing 120-second limit during 10 KiB typing, after all opens and 1 KiB input passed; it never reached JSON serialization. Reduced only CI repetition counts to 20 opens/100 keys per fixture, preserving full 100/1,000 counts in standalone Release mode. The separate unchanged core check failed durable append p95 at 18.27475 ms versus 12 ms; rerunning that exact commit to test known runner variance without touching storage or its gate.
