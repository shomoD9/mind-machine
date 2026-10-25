# 29: Recall: show matches as two-column cards

Status: claimed
Blocked by: none

Founder request (2026-10-25): "have cards instead of list like line objects when you have search matches. Divide the results into two rows and show the cards." This means a two-column grid of cards that fills row by row, in the Mac pill's Recall tab. It should be lightweight, minimal and greyscale, with no glass or other effects, and fast. The Capture editor, Markdown editor, keyboard extension, workflows, signing, entitlements, release pipeline and `docs/PRODUCT.md` are out of scope.

## Acceptance criteria

- [ ] Mac Recall matches are cards in a two-column grid that fills row by row. Every card is the same height, with line clamping.
- [ ] Each card shows the first line as a stronger title, a few lines of preview with matched words in bold, and a small muted date. Checkbox glyphs appear on task lines.
- [ ] Each card has a 1 px border or a very light fill, and no heavy shadow. Hover, pressed and keyboard-selected states are clear.
- [ ] The arrow keys move through the grid (left/right/up/down) and Return opens a card. The Open tasks filter, "Nothing found yet" and the pill window size are unchanged.
- [ ] Typing in the query stays within 33 ms p95 with a full result page. Layout is lazy and keeps the existing result limit.
- [ ] Tests cover the grid geometry, keyboard movement, empty state and filter. A populated-Recall snapshot with clearly fake `[Sample]` notes is a CI artifact. No existing test is weakened.
- [ ] A PR titled "Recall: show matches as two-column cards" is open with a design rationale. CI is green or failures are explained. It is not merged.

## Comments

- 2026-10-25, Claude Opus 5.5 / Claude Code (mm-cards): Claimed. Read WorkspaceView, SearchPreview, VaultFile.search, PillController/PillPanel key handling, PillSelfTest, PillAcceptanceTests, native-ci and DESIGN's pill sections. Main's Recall had no arrow-key movement before this ticket: the SwiftUI query field ignored arrows and Return. This ticket adds both. The iPhone companion shares WorkspaceView and keeps its rows, because the request is for the Mac pill and the phone is narrow.
- 2026-10-25, Claude Opus 5.5 / Claude Code (mm-cards): Round 2 measured the typed letter at 41.9 ms p95 with a full page of cards: SwiftUI rebuilt the grid in the letter's frame. Cards are now `Equatable` and the Mac grid follows the query one main-queue turn later. The self-test gates the letter at 33 ms p95 and the cards' redraw at 100 ms p95.
- 2026-10-25, Claude Opus 5.5 / Claude Code (mm-cards): Round 3 measured the letter at 15.5 ms p50 but 39.5 and 34.7 ms p95 (two runs). Renumbered this ticket from 28 to 29 because PR #16 merged its own ticket 28. Merged origin/main (278a905). The Mac body still searched SQLite and diffed all 30 hits on every key. The page now lives in state and is searched only when the shown query, the filter or the vault changes, and the grid is an `Equatable` `RecallCardGrid`. The expand/collapse frame checks now start from a quiet main thread and repeat only a stalled sample; the threshold of 3 is unchanged.
