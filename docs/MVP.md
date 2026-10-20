# MVP launch design — 20 October 2026

Save a thought without filing it. Find it later in your own words. Continue a conversation that remembers it. Receive an accepted reminder and change it from that conversation.

The human has authorized starting MVP design and attempting a launch today. This document makes the first experience reviewable. It does not declare an unbuilt app launched or replace the complete [PRD](PRD.md).

## Release decision

The human agreed to a private pilot with cross-device sync and explicitly requires the native iPhone secondary keyboard and Mac hotkey today. The browser fallback was rejected. Use the same product foundation for a later public pilot; audience restrictions do not excuse omitting sync or weakening encryption.

Private launch has a tangible distribution advantage: the first external TestFlight build requires Apple review. Public onboarding, account recovery, support, compatibility and operational load also need validation. This does not establish an exact implementation-time difference or make a private pilot automatically robust. [Apple TestFlight](https://developer.apple.com/testflight/)

The repo had no application package at kickoff. Xcode 26.2 is installed; the local signing-identity check returned zero valid identities. Signing and installation need resolution before native iPhone use can be promised. The human is unfamiliar with Developer membership; its purpose was explained and enrollment/signing remain unresolved; no credentials have been requested in chat.

## Current design

[Open the editable FigCraft design](design/native-mvp.figcraft) and [handoff notes](design/README.md). The human requested functional industrial minimalism, entirely greyscale, without brand exploration. The earlier HTML preview is retained only as superseded history.

## The first experience

The keyboard is the primary iPhone workspace. Capture opens by default with a notepad above the keys inside the extension; Find, original inspection, Chat and reminder controls remain in that workspace. The companion app is secondary for setup, settings, recovery and entry points the keyboard cannot support.

Three modes: **Capture · Find · Chat**. Capture opens first. Changing modes preserves the capture and search drafts. Administration stays behind one settings control.

| Mode | Main interaction | Completion evidence |
| --- | --- | --- |
| Capture | Write a thought or essay, paste links, deliberately format bullets or checkboxes, then save. No title or classification required. | The original is persisted before showing Saved. Processing status is separate. |
| Find | Type approximate wording or an exact phrase. Inspect recognizable originals; use Copy or Open. Open tasks is a filter here. | Results link to actual originals. No-match is visible. Keyword-only retrieval must not be labeled semantic. |
| Chat | Continue one retained conversation, grounded in saved captures and prior exchanges. Inspect cited originals. Temporary is a visible segment switch. | Real provider responses and source references; failures keep the user message retryable. No canned response presented as an AI answer. |
| Reminder in Chat | A due reminder appears as an app event linked to its source. Ask to move it, or open Edit/Remove. | Show the actual new date, time and zone after successful scheduling; clarify ambiguous references. |

The app uses greyscale surfaces, one neutral type family, thin dividers, a writing surface with generous space, and small formatting controls. Mode navigation remains within thumb reach on the phone. Search uses a list of originals; no graph or required tag management.

## Writing-space control

Minimised, Default and Expanded sizes preserve the same draft and cursor. Minimised retains a single visible note line and continues typing into the note; it does not redirect input to the host app. Expanded requests more extension height, with exact device limits to be tested. Mac uses a resizable hotkey panel with a fullscreen option; true iPhone fullscreen remains unverified.

See the [size comparison](design/pad-sizes.png) and [platform/roadmap boundaries](ROADMAP.md). Inheritance of the person’s preferred keyboard is a future research item.

## Capture and reminder flow

```text
Capture → Persist original → Saved
                             |
                      Optional soft offer
                             |
                 Date + visible default time + zone
                             |
                 Explicitly set date and reminder
                             |
                      Scheduled / Failed
                             |
          Due event in Chat + permitted external cue
                             |
                      Edit / Remove
```

For a checklist, one date applies to the whole list and selecting it schedules the reminder. Completing every item cancels its pending reminder. An unfinished list stays overdue; no automatic repeating alert. Q33 supersedes the earlier Snooze proposal: rescheduling is an edit. Reopening a completed list offers a new reminder without restoring the cancelled one. Existing reminders retain their original time zone and instant during travel.

The chat reminder event is distinguishable from user and assistant statements. “Move this to tomorrow at 10” uses the linked reminder as its target. “Move my reminder” with several plausible targets requires clarification. A reminder event appearing in chat is not proof that a device notification was delivered.

## Proposed build order

1. Establish signing and native app targets for iPhone, keyboard extension and Mac. Make Capture/Find/Chat usable at phone and desktop sizes.
2. Implement durable local capture, rich text, checklists, reload recovery, deletion and export. Verify originals survive reload before adding intelligence.
3. Implement retrieval with explicit original references. Test paraphrases separately from exact matches. Preserve a reliable keyword path if model processing is unavailable.
4. Connect actual chat inference using an approved local endpoint or explicit cloud opt-in. Retain ordinary exchanges, exclude Temporary segments, and implement Forget against retained and derived data.
5. Implement app-owned scheduling, due chat events, editing/removal and completion cancellation. Test real device delivery separately from foreground timers.
6. Exercise the full loop on iPhone and Mac, publish the verified slice, and commit/push the implementation plus accurate limitations.

This is an implementation sequence, not permission to silently drop release requirements. Browser chat needs a real inference route; a deterministic search response cannot substitute for remembered conversation. A foreground browser timer cannot substitute for reliable closed-app reminders.

## Scope boundaries to show before release

| Capability | Today’s design position |
| --- | --- |
| Text, pasted links, rich formatting, interactive checklists | Core loop. |
| Search and remembered chat | Core loop; retrieval and actual inference need implementation and tests. |
| App-owned reminders and chat rescheduling | Core loop; background delivery is a release gate if reminders are advertised. |
| iPhone keyboard and Mac hotkey | Complete-product requirement. Native surfaces are required today; browser fallback is rejected. |
| Private cross-device sync | Product promise remains service-unreadable. No plaintext database substitute. Included in the private pilot; app-side encryption, key provisioning and real two-device tests are required. |
| Images, voice, OCR/transcription | Full vision. Proposed follow-on to the text loop; not yet an accepted MVP omission. |
| Natural resurfacing | Full vision. Selection priorities remain explicitly deferred. No keyboard card or invented ranking strategy. Proposed follow-on, pending scope acceptance. |
| WhatsApp/SMS | Optional connected channels. No message delivery in the first pilot until explicitly configured and validated. |
| Calendar integration/timeboxing | Already deferred by the human. |
| External assistant/MCP access, imports, pricing | Later design/implementation decisions; no package or price chosen. |

## Launch evidence

- Save a mixed note and checklist, reload/reopen, and recover the exact original.
- Find it with an exact phrase and a paraphrase; report which retrieval modes actually ran.
- Continue ordinary chat after reopening, inspect original sources, and forget an exchange so it disappears from subsequent retrieval.
- Use Temporary with prior vault context, then verify it left no new retained messages or derived memory.
- Schedule a near-term reminder, receive its chat event and the advertised external notification, edit it, remove it, and confirm a completed checklist has no pending alert. Test app-closed delivery if claimed.
- Verify reopened checklists offer a new reminder and travel does not silently shift existing times.
- Confirm cloud processing requires a deliberate opt-in. If sync is present, verify the service cannot read the replicated content.
- Confirm usable iPhone and Mac layouts. A native launch also requires actual keyboard and global-hotkey trials; a browser pilot must identify its surface limitations.

The launch report will distinguish working behavior, tested behavior, and deferred behavior. The full research benchmark remains future validation; passing a small pilot does not establish market demand or production reliability.
