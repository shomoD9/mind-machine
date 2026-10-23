# 13: Sync recovers from transient errors and names the real cause

Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** A one-off database-busy error or a single malformed remote record does not pause sync for the life of the long-running Mac process. Account changes, a wrong key and a removed zone still pause until the person acts.

Today any thrown error sets a stop flag that is cleared only by relaunch. A malformed remote record is also reported as an invalid key, whose message asks for a key. Changing user-facing wording needs the founder's decision, so the new messages are drafted in this ticket for approval first.

- [ ] Fake-cloud tests cover transient (retried next exchange), permanent (paused) and malformed-record outcomes
- [ ] The durable outbox and cursor rules are unchanged
- [ ] New message text approved by the founder before it ships
