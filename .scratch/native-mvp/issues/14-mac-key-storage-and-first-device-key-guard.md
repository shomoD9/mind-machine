# 14: Mac key storage and first-device key guard

Status: ready-for-human
Blocked by: signed Mac and iPhone builds on the founder's team, and a decision on the first-device guard

**What to build:** The Mac app finds the pairing key delivered by iCloud Keychain, and a second device waits for it instead of offering to create a different one.

Review findings that need signed devices to settle: the key query sets an access group and synchronizable flag without the data-protection keychain option, which on macOS may not behave as intended; the setup sheet reads its paired state once, so it does not update when the key arrives; the spec's guard against creating a second key on another device is not implemented; the queued revisions are stored as plain JSON in the sandboxed database and sealed only at upload, while MVP-CORE describes an encrypted queued mutation.

- [ ] Key written on iPhone is readable on the Mac in a signed build (or the failure is recorded)
- [ ] Setup sheet updates when the key arrives
- [ ] Founder decides whether the plaintext outbox is acceptable under file protection, or an encrypted outbox is built
