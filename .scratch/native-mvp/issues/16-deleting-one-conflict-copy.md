# 16: Deleting one conflict copy

Status: needs-info
Blocked by: founder decision on delete semantics; no delete or edit UI exists yet

**What to build:** When a note has two conflict copies, removing one leaves the other visible.

Today a removal is recorded as a tombstone for the whole logical note, and the projection then hides every branch. No screen can delete a capture yet, so nothing is lost today, but the first delete control will hit this. A sibling edit that arrives after a delete must still not resurrect the note, so the rule needs a decision, not a patch.

- [ ] Decision recorded: does deleting a conflict copy remove the note or only that copy
- [ ] Replication test for the chosen rule, including a late edit from another device
