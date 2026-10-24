# 22: Keyboard native look and feel parity

Status: claimed
Blocked by: none

Make the iPhone keyboard extension look and feel like Apple's iOS keyboard: key sizes, spacing, corner radii, key-pop callouts, long-press alternates, shift and caps lock, delete repeat with acceleration, space-bar cursor drag, click sound and haptics, return-key behaviour and landscape. Keep the greyscale, dithered panel; no Next keyboard button; no user-facing copy change. Reuse KeyboardKit 9.9.1 (MIT) and credit it.

- [ ] Audit of gaps against Apple's keyboard in `docs/verification/keyboard-feel-2026-10-24.md`.
- [ ] Each closable gap closed in a small commit, with evidence in the audit.
- [ ] Existing `KeyboardAcceptanceTests` pass; new XCUITests cover testable new behaviour.
- [ ] native-ci green on the PR "Keyboard: native iOS look and feel". Not merged.
- [ ] Founder: feel on a phone (timings, haptics, sound, accents, landscape).

## Comments
