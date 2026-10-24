# 20: Automate keyboard and pill acceptance

Status: claimed
Blocked by: none

The founder requested XCUITest coverage on branch keyboard-ui, verified on GitHub macOS CI because this workspace has no Xcode. The approved seams are the keyboard workspace in a host field and the Mac pill UI, using real local persistence with sync disabled.

- [ ] iPhone Capture acknowledgement, host isolation, prefix/typo Recall, explicit insertion and persisted relaunch.
- [ ] Mode/size draft preservation and real keyplane letters, shift, delete, numbers and return.
- [ ] Mac pill opens and Capture/Recall round-trip, complementing PillSelfTest.
- [ ] Required CI jobs pass; result and remaining device checks recorded.

## Comments

- 2026-10-24, GPT-6 / Codex API: Read project/domain/tracker guidance and ADR 0001. `/tmp/mm-kbui-result.md` was absent. Chose a separate deterministic host target compiling the production keyboard sources: simulator keyboard preferences have produced system-keyboard screenshots on this branch. Test-only storage/proxy adapters must stay outside distribution targets.
