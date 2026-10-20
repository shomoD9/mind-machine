# Headless second brain: research and design

Status: claimed

## Destination

A researched product vision and PRD for the human's whole-day capture, search, and optional resurfacing system. Finish product and UX design before choosing implementation. Record decisions as the grilling proceeds and confirm shared understanding before claiming scope is locked.

## Sources

- Human's brief, 2026-10-19: arbitrary thoughts, reflections, memories, tasks/lists/events/reminders; text, links, images, voice; automatic background organization; strong search; iPhone keyboard; Mac hotkey; optional chat and external LLM access.
- [Research synthesis](../../../docs/RESEARCH-2026-10-19.md).
- [Working PRD](../../../docs/PRD.md).
- [UX journeys and surface blueprints](../../../docs/UX.md).
- [Current glossary](../../../CONTEXT.md).
- Earlier [MVP index](../mvp.md) and [October vision capture](../../../docs/VISION-CAPTURE-2026-10-01.md) are historical inputs. The new scope does not silently close the old interaction tickets.

## Round 1 — answered 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q1: whose day defines the first experience? | “My whole day first.” | Personal and creative situations belong; maker publishing is no longer the sole target job. |
| Q2: records never remembered for search? | Optional resurfacing; multiple strategies; enthusiasm for the feature. Premium packaging floated as a possibility. | Resurfacing is included and optional. Strategy and pricing are open. |
| Q3: “Call Maya tomorrow at 5”? | Save, then offer reminder creation. | Capture alone does not create the reminder. Design the offered action and its result. |
| Q4: processing/privacy? | Ideally local first; free local storage/retriever and compatible local chat access; monetize sync; wants guidance and design/UX before engineering. | Free local experience and paid-sync direction recorded. Sync can preserve usable device copies; cloud processing policy needs a separate decision. No database, model, encryption implementation or cloud stack selected. |

## Round 2 — answered 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q4: privacy promise | Private sync; cloud AI opt-in. | The sync service cannot read the replicated content. Implementation remains undecided. See [privacy decision](../../../docs/adr/0001-private-sync-and-optional-cloud-ai.md). |
| Q5: keyboard role | Secondary capture/search keyboard. | Design activation and return to the usual keyboard. |
| Q6: first resurfacing strategy | Rejected a keyboard card; requested X feed, YouTube Shorts, WhatsApp/SMS deadline cues, and new tabs. Resurfacing should happen naturally during existing idle or browsing moments, across the named surfaces. “Always happens once.” | Preserve the full intended surface set. Frequency, eligible content, and native-versus-web fulfillment need clarification. |
| Q7: chat saving | A single chat remembers everything typed by default; its history can intelligently join the wider corpus. Referenced open-source UNIIChAT. | Default conversation retention replaces inferred-passage saves/receipts and repeated save approvals. Source/quote attribution, correction/deletion, imports, and scope remain to design. |
| Q8: first-release platforms | iPhone and Mac together. | Both belong in the first release. |

## Round 3 — answered 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q9: meaning of “once” | Only one item is shown at a time; no choice between several bookmarks/ideas. Repeats allowed. | This is encounter cardinality, not a once-per-item delivery limit. The cross-surface once-only recommendation was rejected. |
| Q10: content outside the vault | Ideas/bookmarks; private details stay in the vault. | Personal chat passages and private reflections excluded by default; neutral private-deadline cues open details in the vault. Exact eligibility control is Q13. |
| Q11: timed message after declining a reminder? | Timed messages require an accepted reminder. | A captured or inferred deadline alone does not authorize later timed messaging. |
| Q12: phone feed experience | Browser feeds plus new-tab/messages. | Design supported browser integrations on iPhone; no native X/Shorts feed-insertion promise. |

## Round 4 — answered 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q13: full-text eligibility | “what does approve an excerpt mean?” | Clarification requested; no option selected. Explained exact-snippet permission with a mixed private-reflection/idea example and reissued Q13 alone. No approval workflow adopted. |
| Q13, clarified | Automatically show ideas; keep uncertain items private. | Automatic idea/bookmark eligibility is settled. Private or uncertain material remains private. The per-item excerpt-approval proposal is rejected. |
| Q14: tap destination | Thought opens original; bookmark opens link. | Thought opens the original private reading view, with Continue in chat available; bookmark opens its saved destination. |
| Q15: scrolling past | Still eligible; explicit control stops it. | Passing leaves repeat eligibility; Stop showing this excludes the item from resurfacing while preserving it. |
| Q16: entry mode | Capture by default. | Mac hotkey and secondary keyboard open Capture; one toggle reaches Find and preserves drafts. |
| Q17: forgetting | Delete original and derived memory. | Remove selected exchange and derived memory across synced devices; previously shared external copies remain a separate boundary. |

## Round 5 — answered 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q18: selection priorities | “we'll think this later” | Explicitly deferred. No selection strategy chosen; do not re-ask in the current round. |
| Q19: current-page context | Use only my captured material. | Resurfacing selection excludes current-page/topic context and general browsing history. Retained ordinary chat is already part of the corpus. |
| Q20: to-do lists | Interactive checklist linked to capture. | Items can be ticked off while retaining their original source; capture alone creates no reminder. |
| Q21: continuing-chat placement | Chat is also a keyboard mode. | Add Chat beside Capture/Find. Exact compact layout, companion access, and Mac placement remain to design; no automatic app-opening promise. |
| Q22: Temporary mode | Offer Temporary mode. | Explicit segments stay out of retained vault history and derived memory. Reading prior memory and segment lifecycle are unsettled. |

## Round 6 — answered and refined 2026-10-20

| Question | Human answer | Recorded meaning |
| --- | --- | --- |
| Q23: clearly written lists | Asked for clarification and described action sentences with a soft post-save reminder offer, formatted bullets/checkboxes, checklist due-date prompts, and essay-length visual Markdown editing. | Full lightweight rich-text capture is settled. Respect explicit list formatting. The earlier automatic-list conversion proposal is superseded. Optional checklist due-date versus reminder and date scope need Q27–Q28. |
| Q24: unfinished items | Open tasks in Find and Chat. | Aggregate access keeps links to original captures. |
| Q25: reminder ownership | App owns reminders; future optional Apple/Google Calendar connections can support calendars and timeboxes. Solve current problems first. | Reminder ownership is internal. Calendar integrations/timeboxing are deferred; no current bidirectional-sync or automatic-timeboxing commitment. |
| Q26: Temporary access | Can read the vault; saves nothing new. | Temporary may use relevant saved material, while no new segment messages or derived memory are retained. |

## Design tree and current frontier

```text
Whole-day personal vault [settled]
├── Capture without filing + strong search [brief]
│   ├── iPhone keyboard [vision]
│   │   └── Secondary keyboard [settled Q5]
│   ├── Mac hotkey [vision]
│   └── iPhone + Mac first release [settled Q8]
├── Optional resurfacing [settled]
│   ├── X / Shorts / new tab / WhatsApp-SMS [requested Q6]
│   ├── One item per encounter; repeats allowed [settled Q9]
│   ├── Private details stay in vault [settled Q10]
│   │   └── Automatic eligibility; uncertain stays private [settled Q13]
│   ├── Browser phone journey [settled Q12]
│   ├── Thought → original; bookmark → link [settled Q14]
│   ├── Passing keeps eligibility; explicit stop excludes [settled Q15]
│   ├── Selection priorities [deferred by human Q18]
│   └── Captured material only; no current-page context [settled Q19]
├── Save then offer reminders [settled]
│   ├── Timed messages require accepted reminder [settled Q11]
│   ├── This app owns reminders [settled Q25]
│   ├── Soft post-save reminder prompt [Q23 refinement]
│   └── Time / channels / edits / failure [next]
├── Continuous chat + retained history [settled Q7]
│   ├── Forget original + derived memory [settled Q17]
│   ├── Chat also in keyboard [settled Q21]
│   ├── Temporary segments [settled Q22]
│   │   └── Read vault; retain nothing new [settled Q26]
│   └── Attribution / imports [next]
├── Captured to-do lists
│   ├── Interactive linked checklists [settled Q20]
│   ├── Rich editor with explicit bullets/checklists [settled Q23 refinement]
│   ├── Open tasks in Find and Chat [settled Q24]
│   ├── Q27 due date versus alert [pending]
│   └── Q28 whole-list/item date scope [pending]
├── Capture/search entry
│   └── Capture first; toggle Find; preserve drafts [settled Q16]
└── Free local + paid-sync direction [stated]
    └── Private sync; cloud AI opt-in [settled Q4]
        └── Offline / recovery / sharing controls [next]
```

Round four is complete. Q13's clarified excerpt-approval recommendation was rejected in favor of automatic eligibility with uncertain items private. The clarification remains in the table as interview history, not a current workflow.

Round five is answered; Q18 is explicitly deferred. The current-page-context recommendation was rejected in favor of captured material only, and Chat is added to the keyboard. Checklist and Temporary behavior are accepted as above.

Round six is answered. The editor/post-save-offer refinement replaces the earlier “clearly written lists” proposal. Selection priorities and calendar integration/timeboxing remain deferred. Current questions Q27–Q28 recommend a due date plus a separate optional reminder control within the same soft prompt, and a whole-list date with optional item dates. These remain unanswered.

Research references: [UniiChat identity and memory](../research/22-uniichat-identity-and-memory-2026-10-20.md), [surface contracts](../research/23-resurfacing-surface-contracts-2026-10-20.md). Chrome verified the creator's source-release X post. Browser feed/new-tab capability is documented; native iPhone feed insertion has no supported route. These findings do not select an implementation or substitute an experience without the human's answer.

## Completion condition

Every included behavior is concretized with the human, contradictions with the older scope are reconciled, and the human confirms shared understanding. Until then this ticket remains claimed and the PRD remains a draft. No implementation work has begun.
