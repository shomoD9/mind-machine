# Capture here. Recall here.

The core problem is losing access to something already encountered, thought or saved when it becomes useful. The MVP should let a person save a memory and recover its original from their current activity, on either iPhone or Mac, without filing it or opening a separate notes workspace.

Updated 22 October 2026 from the human's latest clarification. In-place Capture, Find, resident local copies and sync from day one are explicit requirements. The Mac should have a persistent movable control that expands from its anchor; the hotkey remains an additional entry. The proposed deferral of Chat, reminders and resurfacing is awaiting the human's answer. Existing implementation and earlier requirements remain preserved until that scope decision. This document proposes release acceptance; it does not declare the development build ready.

## The product promise

**When something occurs to me, I can put it away immediately. When I need it, I can recover and use it without leaving what I am doing.**

The system accepts an explicit capture and preserves its original. The person never needs to choose a category, write a title, organize a collection or start a conversation to find it. Local search can use remembered words, misspellings and meaning. Results expose recognizable originals and a deliberate Copy, Insert or Open action.

This promise covers captured material. Capturing the person's entire browsing or host-app history is not implied. Optional future resurfacing addresses memories the person never thinks to search for; the current release recommendation focuses on intentional capture and recall.

## Jobs and acceptance stories

| Situation | Job | Evidence required |
| --- | --- | --- |
| A thought arrives while writing a message | Save it without abandoning the message | Switch to our keyboard, capture, save, return to the preserved host draft; ordinary host typing is never saved as a note |
| A previously saved detail becomes useful | Find the original with whatever clue I remember | Keyboard Find returns exact/typo and independently tested paraphrase matches; inspect and explicitly insert/copy the original |
| Working in a Mac app | Keep memory access visible and within reach | A small control remains available across supported ordinary apps/Spaces; click to expand Capture/Find at its position, dismiss back to the anchor; hotkey also opens it |
| Moving between phone and Mac | Trust that a saved memory is available on the other device | Keyboard-only save reaches Mac Find, and Mac save reaches keyboard Find, without manually opening a companion workspace |
| Losing connectivity | Continue capturing and recalling | Previously downloaded sources and indexes remain usable; new saves persist and queue; reconnect converges without losing concurrent originals |
| Forgetting exact wording | Recall by meaning without configuring an AI server | A local semantic path is tested against judged queries; word matches appear promptly; no Ollama URL, model name or category setup in everyday flows |

## Two surfaces, one memory

```text
iPhone, inside a supported host app
+-----------------------------------+
| Host conversation and draft        |
+-----------------------------------+
| Capture | Find              Size  |
| Private note or live results      |
| [expand / minimise, draft retained]|
| Familiar typing keys              |
+-----------------------------------+

Mac, over the current workspace
   collapsed            expanded from its anchor
   +---+                +---------------------------+
   | • | -- click -->   | Capture | Find        ×   |
   +---+                | Write / paste / search... |
   movable control      | Note or original results  |
                        +---------------------------+
```

The exact collapsed shape/placement is functional design work; a brand kit is unnecessary. Greyscale, readable text, familiar controls and retained drafts remain the direction. Collapse keeps the entry visible; it does not submit or discard text. Expanding takes keyboard focus for our field; dismissal returns to the prior app. Focus/routing and explicit insertion remain separate operations.

The iPhone surface uses our own custom keyboard with an expandable private pad. Apple's documented extension API does not provide an embeddable copy of another installed keyboard. Secure fields and apps rejecting custom keyboards remain platform exceptions. On Mac, a floating AppKit panel can supply the intended entry without reading another app's text; optional focused-field geometry remains a separate enhancement. User hide/quit controls must remain available. No universal overlay above security/system surfaces is promised. [Platform and client research](research/2026-10-22-grammarly-form-factor-reuse.md).

## Local residency and sync

Keep a protected local source store and search index on each device. Confirm Saved after the local durable transaction; queue a small encrypted mutation in the same transaction. Network transfer and optional enrichment run independently. Search queries use that local copy and do not wait for the server. Initial pairing shows download/index progress and a clear incomplete state until the promised corpus is available.

Keep downloaded source records and agreed offline media in app-managed storage, without automatic cloud-placeholder eviction. A storage-full failure preserves the draft and shows an actionable message; no unconditional claim that unlimited media fits on any device. Deleting a remote account, signing out or changing accounts must not silently delete or cross-upload the resident vault.

CloudKit with a local SQLite store can provide this arrangement. iCloud Drive folder eviction is a separate design. An Obsidian-like custom service can also provide it. Select transport from measured keyboard/companion lifecycle, active-device convergence, operating cost and privacy behavior, rather than assuming either brand of transport is intrinsically faster. [Local-resident sync research](research/2026-10-22-local-resident-sync-mvp.md).

The previously chosen service-unreadable sync and opt-in cloud AI remain constraints. Speed, familiarity and convenience guide the implementation within those promises. Retain concurrent source revisions and prevent deleted material returning from stale replicas.

## Search and image scope

MiniSearch uses BM25+ for word ranking, with prefix/typo features. It can index a note's text, extracted image text and captions. It does not convert pixels into meaning. Semantic text recall requires an encoder; text-to-image recall requires an image encoder and a compatible text encoder in a shared vector space. Both can feed one Find interface, with links back to the exact saved source. [Multimodal research](research/2026-10-22-multimodal-memory-search.md).

The following are distinct promises to accept and verify:

- Text/links: the original and URL are findable, including a tested paraphrase path.
- Images: save the original via a supported paste/share path, expose a thumbnail and recover it by extracted text/caption; visual-concept retrieval requires the paired encoder pilot to pass before being advertised.
- Voice: retain an original recording and searchable transcript if voice is included. The keyboard cannot simply inherit a microphone-recording capability; define its capture entry and transcription lifecycle separately.

The full vision includes images and voice. This refinement does not silently approve their omission from MVP. It also does not treat a question about MiniSearch as approval of an untested visual-search implementation. Final first-release media acceptance remains explicit scope work.

## Recommended release boundary

Make Capture → Find → reuse, native entry points, local residency and private sync the release-critical loop. Keep Chat, reminder automation, natural resurfacing, calendar integration and external assistant access as preserved future/product capabilities unless the human keeps them in this release. Existing authored checklists, rich formatting and draft behavior can remain; they must not delay the core save/recall flow. This recommendation awaits the scope answer and does not rewrite approved tickets.

The smallest demonstration that proves this product is useful:

1. Save a thought from the iPhone keyboard while another supported app is open. The host draft remains intact.
2. On Mac, click the visible memory control and retrieve that thought with different wording. Reuse the original in the current activity.
3. Save a different note on Mac. Retrieve it inside the phone keyboard without opening the companion.
4. Disconnect both devices. Capture and recall locally, restart the processes, then reconnect. Verify acknowledged captures, concurrent edits and deletion converge correctly.

Word matching alone, a manually refreshed companion or a cloud-only result would leave parts of that demonstration unmet. No current build has passed the complete sequence.

## Speed evidence to collect

Use the [existing proposed latency/quality budgets](research/2026-10-22-fast-private-retrieval.md#proposed-acceptance-budgets--all-unmeasured) as starting targets: warm first-visible local matches p95 below 50 ms and semantic enrichment below 150 ms at 10k realistic captures, with cold activation and memory reported separately. For sync, the proposed active-device target is p95 within 3 seconds under a defined healthy connection; background delivery has no fixed OS deadline. These are targets, not achieved application measurements.

Measure the person's whole action: open, type, see the right original, reuse. Also measure cold keyboard launch, save-to-local-find, keyboard-to-Mac, Mac-to-keyboard, keystroke stalls, extension termination and index readiness after pairing. A fast library query alone cannot establish the experience. Reuse candidates and the isolated MiniSearch Mac benchmark are evidence for pilots, without a production performance claim.

## Reuse and next decisions

- SnipKey typing layer, preserving our accepted notepad and destination routing.
- EdgeNoted's MIT edge-panel/windowing approach for the Mac control; draggable anchoring still needs adaptation and verification.
- MiniSearch versus FTS5 through one retrieval interface; cached semantic vectors remain independent.
- Local-store plus CloudKit or a compatible non-iCloud replication engine, conditional on real keyboard-process proof and the encryption/key lifecycle.
- A licensed paired image/text encoder if semantic images are included; OCR alone supports a narrower explicit promise.

This is the revised product lens for the pending [execution plan](../.scratch/native-mvp/plans/consumer-backend-2026-10-22.md). Research and a scope proposal have been produced; no production feature or dependency changes are implied.
