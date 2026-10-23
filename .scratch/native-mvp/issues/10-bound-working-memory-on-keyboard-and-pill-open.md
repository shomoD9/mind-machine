# 10: Bound working memory on the keyboard and the Mac pill open path

Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Saving, completing a checklist item or reconciling a reminder from the keyboard touches only the captures involved, so the 100-capture keyboard window holds. Opening the Mac pill does not read every capture on the main thread before the animation starts.

Found by the 2026-10-23 review: the vault store's whole-vault mutation reads and decodes every capture twice per edit, including inside the keyboard process; the 15-second reload and the pill's Capture activation both do a full vault read on the main actor. Today's pill timings were taken on a near-empty vault, so they show no regression signal. Related in-memory quirk: with the keyboard window, saving a note drops the newest older note from the in-memory list (list is newest-first but the trim keeps the tail).

- [ ] A store-level test shows an edit of one capture in a 10k-capture vault decodes a bounded number of captures
- [ ] Keyboard-mode model never holds more than its window after save, edit or reload, and keeps the newest notes
- [ ] Pill expand with a 10k-note vault is measured in macOS CI and the median stays within the current budget
- [ ] No change to what the person sees
