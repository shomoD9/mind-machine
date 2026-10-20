# 01 — Capture and refind from native entry points

Status: claimed
Blocked by: none
Spec: [Native MVP](../spec.md)
Review baseline: c319917

## Acceptance criteria

- [ ] iPhone companion and embedded keyboard extension compile as native targets. Mac native app registers a global hotkey and opens a dismissible panel.
- [ ] Explicit keyboard/panel capture saves original wording locally, survives reopening and returns through keyword Find with the original accessible.
- [ ] Capture is the default. Find is one toggle away. Inserting a recovered original into the host requires an explicit action.
- [ ] Use shared device storage only when its App Group is available; expose unavailable sharing rather than silently separating companion and keyboard vaults.
- [ ] Exercise real persistence/refinding through the saved-vault interface; compile all targets and run a native smoke check. Report signing/device constraints separately.

## Verification

- Xcode 26.2 compiled all three native targets. The iPhone app embeds the keyboard extension.
- Saved-vault test was red before findCaptures existed, then passed; it saves, reopens through another storage caller and refinds the exact original.
- Workspace activation regression was red before activateCapture existed, then passed; Capture opens while all drafts remain.
- Full package suite: 10 tests passed. Shared Core/UI modules compile on Mac and iOS.
- Companion installed and launched in the existing iOS 17.5 simulator. Ad-hoc signing registered the shared App Group; setup screenshot inspected.
- Standards: 0 remaining code findings after fixes to living docs, narration and shared retrieval. Spec: 0 remaining code findings after Capture-on-reactivation fix.
- Still required: enable/use the actual keyboard, save/find/Insert through it, and exercise the Mac global hotkey. Native UI automation cannot proceed while the Mac is locked. Keep this ticket claimed until those acceptance checks are done.
- Real-phone signing/device proof remains a release gate. No encrypted sync or launch claim.

See [checkpoint report](../../../docs/verification/native-capture-checkpoint.md).

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Claimed to implement the first vertical slice.
- 2026-10-20: Code review used approved c319917, including tracked and untracked changes. This is an in-progress source checkpoint; later tickets remain dependency-blocked.
