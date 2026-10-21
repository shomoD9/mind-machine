# Native keyboard-first MVP — build specification

**Status:** approved on 2026-10-20. Product behavior comes from the current PRD, UX, FigCraft design and the human's later clarifications. The human approved all three test boundaries, eight tickets and review baseline c319917.

## Problem Statement

The person has thoughts, links, memories and commitments during other activities. Filing and revisiting separate apps adds friction. They need to save immediately, recover approximate ideas later, receive accepted reminders and continue a remembered conversation without maintaining a collection.

## Solution

A secondary iPhone keyboard is the primary phone workspace. Capture opens with a private notepad above the keys. Find, original inspection, Chat and reminder controls stay there while a supported host app remains open. A Mac global hotkey opens the same core workflow in a native panel. Each device has usable local material; private replication connects their vaults. The companion app handles setup, settings, recovery and capture paths unavailable to a keyboard.

## User Stories

1. As the person, I want Capture when I activate the keyboard, so that I can save a thought immediately.
2. As the person, I want to write without naming or filing the capture, so that storage requires no organizational decision.
3. As the person, I want mixed thoughts and original wording preserved, so that later processing retains context.
4. As the person, I want visual rich-text controls, bullets and explicit checkboxes, so that a short thought or essay is easy to write.
5. As the person, I want to minimise, restore or expand the note, so that I choose how much host content I can see.
6. As the person, I want both drafts and carets preserved while resizing, so that my writing is not interrupted.
7. As the person, I want minimising alone to keep my current destination, so that keys do not silently change where they write.
8. As the person, I want to select the host text field or notepad deliberately, so that the same keyboard can serve either.
9. As the person, I want the active typing destination visible, so that private notes do not accidentally become host messages.
10. As the person, I want the host composer above the whole workspace, so that I can keep using it as the note grows.
11. As the person, I want Find one toggle away with drafts preserved, so that retrieval interrupts me briefly.
12. As the person, I want exact phrases and approximate wording to work, so that I can refind material with incomplete recall.
13. As the person, I want recognizable originals and their dates/sources, so that I can judge what a result means.
14. As the person, I want an explicit Insert action, so that recovering a note does not automatically alter my host draft.
15. As the person, I want a Mac global hotkey and a dismissible resizable panel, so that capture/search are available while working elsewhere.
16. As the person, I want a visible save result after persistence, so that I know whether my thought is retained.
17. As the person, I want processing and sync status separate from saving, so that slow processing does not make local capture ambiguous.
18. As the person, I want a soft reminder offer after saving an action sentence, so that I choose scheduling separately from capture.
19. As the person, I want a whole-checklist date to schedule its reminder, so that there is one clear commitment action.
20. As the person, I want a visible editable default time and time zone, so that a date-only choice has no hidden alert time.
21. As the person, I want completing every item to cancel the pending reminder, so that completed work does not keep prompting me.
22. As the person, I want unfinished work to remain overdue without automatic repeats, so that reminders do not become nagging.
23. As the person, I want reopening a completed list to offer a new reminder, so that a cancelled alert does not return unexpectedly.
24. As the person, I want due reminders in Chat as app events, so that I can refer to them when editing a schedule.
25. As the person, I want edit/remove controls and conversational rescheduling, so that commitments are manageable from their context.
26. As the person, I want existing schedules to keep their original time zone, so that travel does not silently move deadlines.
27. As the person, I want one continuing remembered conversation, so that I can return without starting over or saving passages manually.
28. As the person, I want user statements, assistant output, quotations and uncertainty distinguished, so that conversation history does not become false personal facts.
29. As the person, I want Temporary segments to read my vault without retaining new content, so that private questions remain temporary.
30. As the person, I want Forget to remove the selected exchange and derived memory, so that it stops returning across synced devices.
31. As the person, I want originals available offline and replication private, so that capture survives network loss without giving the service plaintext.
32. As the person, I want understandable key-wait, conflict and account-change behavior, so that sync does not silently overwrite or strand material.
33. As the person, I want explicit cloud-AI opt-in, so that sync does not imply permission to send content to inference providers.
34. As the person, I want images/audio and their extraction state linked to originals, so that processing failure does not lose what I saved.
35. As the person, I want optional natural resurfacing one item at a time, so that I can rediscover forgotten material without a review ritual.
36. As the person, I want private or uncertain material excluded from external plaintext encounters, so that automatic resurfacing respects the vault boundary.
37. As the person, I want Stop showing this to affect resurfacing alone, so that useful originals remain searchable.
38. As the person, I want exports and clear installation/recovery steps, so that I can trust and operate the pilot.

## Implementation Decisions

- On 21 October the human accepted the installed keyboard editor and retaining a visible dormant host caret while the private note receives typing. A guarantee of exactly one visible caret across host apps is not an MVP requirement. The active route remains labelled; other host/device limitations stay explicit.

- Swift native clients share the existing Vault domain and coordinated persistence. The keyboard controller owns a private input route and a host-proxy route, with explicit destination state.
- Size and mode changes preserve destination, private selections and drafts. Native host-focus behavior needs a runnable experiment before universal tap-to-focus is promised. A visible destination selector is a proposed fallback, not a silently approved replacement.
- Background organization begins with provenance, timestamps, URLs, author-chosen structure, keyword indexing and optional on-device embeddings. A permanent category taxonomy is not a prerequisite. Interpretations remain replaceable and never overwrite original material.
- Reminder creation, edit and removal are explicit operations. System-notification outcome, due Chat events and user reading are separate facts. A foreground timer is not proof of background delivery.
- Chat uses real configured inference with original references, attribution and explicit privacy choices. Local inference availability and cloud processing are distinct from storage/sync. Generated text cannot claim actions that were not executed.
- Proposed private replication uses app-encrypted per-record payloads over CloudKit with guarded key establishment. A normal private database alone does not satisfy the service-unreadable promise. Keep key setup, local mutation queue, conflicts, deletions and account isolation explicit.
- Keep phone companion setup/media/recovery secondary. Use permitted browser integrations for resurfacing; native-feed insertion and universal keyboard inheritance are unverified ambitions.
- The existing native foundation is a starting point, not proof of product completeness. Current provider assumptions, schema and module names can be improved through behavior tests without breaking original-preservation or privacy contracts.

## Testing Decisions

- Use the three approved public test boundaries: keyboard workspace session, saved vault and encrypted two-vault replication. Native host/device checks remain separate evidence.
- Test observable caller/user behavior, preserving literal expected outcomes from this specification. Use the real local storage adapter and existing Vault tests as prior art.
- Build one failing behavior test and its minimal implementation at a time. Keep native app/controller checks tied to real state and user actions rather than visual pixel snapshots.
- Replace external inference/CloudKit/time with controlled adapters where needed. Avoid mocks of internal modules and private callback assertions.
- Compile iPhone app, embedded keyboard and Mac targets. Verify layout/focus with actual native tests, then real-device behavior separately. Compilation does not validate host tap routing, notification delivery, encryption deployment or two-device key convergence.
- Test cross-device offline mutations, conflict preservation, deletion without resurrection and notification cancellation after sync before claiming that contract.

## Out of Scope

- Brand exploration, a public signup launch as today's default, mandatory filing, a keyboard resurfacing card and per-passage chat-save approval are excluded by current decisions.
- Calendar integration/timeboxing and resurfacing-selection priorities remain explicitly deferred. Do not choose a strategy in implementation to bypass that decision.
- No claim of exact Apple-keyboard parity, universal third-party-app availability, native feed injection or true fullscreen keyboard height is established.
- No cloud-provider credentials, paid memberships, legal agreements, live message delivery or account changes are authorized merely by this specification.
- These boundaries do not silently cut unresolved media or resurfacing features from an advertised release. Report decision-blocked work and agree launch scope before calling the pilot complete.

## Further Notes

The local engineering tracker continues the existing convention. The spec and eight individual tickets are approved and published. The current greyscale FigCraft design is a reference for functionality; desired state diagrams do not establish platform feasibility. Apple membership/signing and actual device testing remain external prerequisites for a complete synced native launch.
