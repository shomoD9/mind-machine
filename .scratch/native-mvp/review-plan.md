# Native MVP engineering plan — draft for approval

**Status:** needs-info — workflow confirmation requested under ask-matt.

The human has authorized building the native MVP. This draft makes Matt Pocock's required setup, test boundaries and ticket breakdown reviewable before new tests or feature work. Existing product decisions stand; this is not another product interview.

## Setup draft

The repo already uses local Markdown tracking under `.scratch/`; keep it. Use `.scratch/native-mvp/spec.md` for the approved build specification and one file per implementation ticket in `.scratch/native-mvp/issues/`. Preserve the earlier product/wayfinding tracker and its open tickets.

Neither a root `AGENTS.md` nor `CLAUDE.md` currently exists. Recommend creating `AGENTS.md`, retaining the human's supplied writing, DESIGN, journal and code-narration instructions and appending this block:

```markdown
## Agent skills

### Issue tracker

Track engineering work in local Markdown under `.scratch/`. Before publishing or claiming tickets, read `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage roles. Before changing ticket status, read `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context glossary and ADRs. Before implementation or review, read `docs/agents/domain.md`.
```

Proposed `docs/agents/issue-tracker.md`: local Markdown; one feature directory; `spec.md`; one numbered issue file per ticket; `Status:` and `Blocked by:` near the top; discussion under Comments. A ticket becomes ready when its real blockers are resolved. Hosted GitHub Issues are not introduced.

Proposed `docs/agents/domain.md`: read `CONTEXT.md` and relevant `docs/adr/` decisions before implementation; use glossary terms; flag contradictions; update `docs/DESIGN.md` and the journal as required. This is one domain context even though there are multiple native targets.

Proposed `docs/agents/triage-labels.md`: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix` map to themselves. Keep resolved/claimed historical wayfinding conventions in that older tracker.

## Test boundaries to confirm

1. **Keyboard workspace session:** exercise typing into the selected destination, switching destination, size/mode changes, selection/caret preservation and draft survival through the public session interface. Expected behavior comes from the agreed user journeys. Native tests additionally check actual host focus callbacks, composition and height constraints; a pure state test cannot establish those facts.
2. **Saved vault:** exercise capture, reload, exact/semantic retrieval, retained/Temporary conversation behavior, source inspection, accepted reminders, completion/cancellation, rescheduling and Forget through the caller-facing interfaces. Keep the existing Vault/VaultFile checks as prior art. Avoid mocks of internal modules and assertions about callback counts or private fields.
3. **Encrypted replication:** exercise two independent local vaults exchanging ciphertext through the sync interface. Prove offline retry, key-wait behavior, conflict preservation, deletion without resurrection and reminder reconciliation. CloudKit and inference are external test adapters; real-account/device tests remain separate release evidence.

Verify UI behavior in the actual native shells. Compile all three targets and use simulator/Mac smoke checks for editing, search, focus, mode changes and reopening. Do not test decoration or duplicate implementation constants. No new test will be written until these boundaries are confirmed. Implementation proceeds one failing behavior test → minimal passing change → next behavior; review follows.

## Ticket breakdown to confirm

These are proposed vertical slices, not published tickets. Each includes native UI, persisted behavior and verification for its path.

1. **Capture and refind from native entry points**
   - **Blocked by:** none after workflow approval.
   - **Delivers:** iPhone app plus embedded keyboard extension and a Mac global-hotkey panel; explicit capture persists, survives reopening, and returns through keyword Find with the original accessible. No separate frontend-only or storage-only ticket.
2. **Write comfortably and select where keys go**
   - **Blocked by:** 1.
   - **Delivers:** visual rich-text note controls; Minimised/Default/Expanded preserve drafts/carets/active target; host versus private input is visible and explicitly selectable; native evidence determines which tap-to-focus transitions work. No claim of universal fullscreen or Apple typing parity.
3. **Capture a checklist, accept a reminder, and change it**
   - **Blocked by:** 1, 2.
   - **Delivers:** explicit checklists; Open tasks; whole-list due date with visible default time; app-owned system reminders plus due Chat events; edit/remove, completion cancellation, overdue state and new offer after reopening. Device delivery is verified separately from foreground events.
4. **Find meaning and continue a remembered conversation**
   - **Blocked by:** 1, 3 (the reminder-rescheduling path genuinely needs reminder behavior).
   - **Delivers:** local semantic retrieval when available with honest fallback; searchable attributed conversation; a real configured inference route; Temporary read access without retention; Forget; original references; explicit chat reminder edits with visible outcome. Cloud processing remains opt-in. Fixed folders/category taxonomy are not a prerequisite; automatic metadata remains replaceable.
5. **Use the same private vault on iPhone and Mac**
   - **Blocked by:** 1, 3, 4 (sync must cover the implemented capture, commitment and conversation lifecycles).
   - **Delivers:** local-first encrypted replication, guarded first-device key establishment, second-device key wait, offline mutations, conflict preservation, deletion and notification reconciliation. Includes the signing/entitlement setup path. Source implementation can proceed while account prerequisites are unresolved; successful real sync cannot be claimed before actual two-device proof.
6. **Capture media and recover its original**
   - **Blocked by:** 1.
   - **Delivers:** supported image/audio/file input through permitted native entry points, original attachment persistence, visible extraction state and supported OCR/transcript search linked to the original. Keyboard microphone constraints use a deliberate companion capture path. Supported formats/limits are declared rather than implying unlimited storage or universally available local transcription. Sync integration is verified with 5 at release.
7. **Return saved material in enabled browsing surfaces**
   - **Blocked by:** 1 and the human's explicitly deferred resurfacing-selection decision. Integration with private sync is verified with 5.
   - **Delivers:** one eligible item per encounter, repeat/stop behavior, original/link destination and the privacy boundary in enabled browser/new-tab surfaces. No native-feed insertion promise or keyboard resurfacing card. This ticket stays decision-blocked; no ranking strategy is chosen by the agent. Optional WhatsApp/SMS need their own configured and accepted delivery, with no unsolicited live messages.
8. **Install and verify the native pilot**
   - **Blocked by:** 1–6, plus the human's release-scope choice for decision-blocked ticket 7 and actual Apple account/device prerequisites.
   - **Delivers:** runnable Mac app and installed real-iPhone keyboard, repeatable setup steps, exercised core loop and sync on real devices, exports/recovery, explicit known limitations, reviewed code and committed/pushed artifacts. A simulator build, mock chat or screenshot alone is not launch evidence. No same-day Apple approval time is promised.

## Review and publication

Use the existing baseline `c319917` for the engineering diff unless the human chooses another reference. Confirm that choice together with the plan. At ticket completion, run appropriate focused checks, then Standards and Spec reviews in separate agents as required by code-review. Address findings, validate the completed ticket, then commit and push under the human's continuing instruction.

The review skill's commit-diff mechanics will be followed with a fixed baseline and a reviewable diff; uncommitted implementation must also be included so pre-commit review does not miss it. Do not announce a ticket complete until its full acceptance criteria are met.
