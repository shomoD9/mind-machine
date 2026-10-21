# 02 — Write comfortably and select where keys go

Status: claimed
Blocked by: 01
Spec: [Native MVP](../spec.md)
Review baseline: c319917

## Acceptance criteria

- [ ] Lightweight visual rich-text controls support prose, bullets and explicit checkboxes while preserving originals.
- [ ] Minimised, Default and Expanded preserve drafts, selections, mode and destination. Minimising alone keeps typing into the selected note.
- [ ] Host input and private input are visibly distinct. Tap the note to select it and tap the host composer to select host input where native focus allows; verify callbacks rather than claiming universal behavior.
- [ ] The representative native test host anchors its composer above the complete extension workspace. Other hosts own their geometry.
- [ ] Prove destination and editing behavior at the approved workspace seam; document real native focus/height observations and Apple-parity/fullscreen limits.

## Verification

- All three native targets compile; full package suite passes 16 tests.
- Red→green public tests cover sizing/context preservation, independent mode drafts/carets, safe asynchronous send acknowledgement, original+RTF persistence, explicit visual checkbox capture and native multi-paragraph list authoring through save/reopen.
- Mac UI bold → save → Find → original retained bold; screenshots and AX verified it.
- Simulator default layout inspected: Size/formatting controls render and the representative host composer stays above the whole workspace.
- Independent Standards and Spec reviews found no remaining code findings after fixes. Human keyboard QA passed sizing/selection preservation and formatted save/reopen. Tap routing initially failed. The proxy-identity fix passed note → host → note with basic hardware input in the simulator test host. The human confirmed on-screen-key routing on 21 October. Both carets remain visible during Private note routing; CUA verified the private caret hides during App routing. Host caret styling is unavailable through the reviewed public proxy API. The human confirmed private-caret recurrence during App routing and reported simple-tap menus. The installed geometry/menu candidate failed full focus/selection acceptance. Latest report says App hides the private caret, but host caret remains in Private mode and ordinary taps produce word-selection/replacement menus. A built, uninstalled private-spelling candidate removes the failed custom menu gate. Apple-keyboard human baseline is pending. Single-caret behavior across arbitrary hosts is unsupported; ticket stays claimed.
- [Detailed evidence](../../../docs/verification/native-editing-checkpoint.md). Real-device and universal-host proof remain release limits.

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Waiting for the listed blockers.
- 2026-10-20: Ticket 01 resolved after human keyboard-flow confirmation. Claimed this next approved slice; test boundaries remain the previously approved workspace and saved-vault interfaces.

- 2026-10-21: Human confirmed custom-key routing passes and reported simultaneous cursor blinking. Reproduced dual visible carets in Private note, verified local caret hides in App, inspected public SDK/proxy docs, and recorded host ownership without claiming a universal fix. No code/settings changes.
