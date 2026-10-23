# 17: Keyboard and model leftovers from the 2026-10-23 review

Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Small cleanups that do not change what the person sees.

- [ ] The keyboard no longer writes its memory report to the shared container on every search render; once per few seconds keeps the measurement useful for the founder's headroom check
- [ ] A failing search does not republish the error from inside a SwiftUI body on every render
- [ ] Sending a chat message searches with the message as an argument instead of temporarily rewriting the published query
- [ ] The database busy timeout (5 seconds) is not taken on the main thread by a read that a keyboard write could block
- [ ] Unreachable keyboard Chat mode branches and the reserved pill mode are removed or marked as deferred code
- [ ] Highlight fonts in the keyboard follow Dynamic Type
- [ ] Leftover names (hotkey signature, vault folder, reminder prefix) are listed as deliberate compatibility choices in the design document or renamed with a migration
