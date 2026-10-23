# 12: Split the vault store along its reasons to change

Status: needs-info
Blocked by: 10-bound-working-memory-on-keyboard-and-pill-open

**What to build:** Storage encoding, Recall index, revision log and legacy migration live in separate internal modules behind the unchanged store interface, so a search change does not touch replication code.

Smells from the review: one 400-line file edited for four unrelated reasons; the storage encoding (base64 versus text beginning with a brace) leaks into every query helper; the hit-decode and open-tasks filter block appears three times; the JSON-to-text encode appears four times; the capture copy appears three times; the typo-dictionary table is never pruned when a note is edited or deleted.

- [ ] Existing store, replication and 10k performance tests pass unchanged
- [ ] Duplicated blocks above have one home each
- [ ] Editing or deleting a note removes spellings no other note uses
