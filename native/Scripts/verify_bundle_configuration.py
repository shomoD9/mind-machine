#!/usr/bin/env python3
"""Read built bundle metadata in macOS CI to prove xcconfig expansion.
The iOS and Mac build jobs call this against real .app/.appex products.
"""
from pathlib import Path
import plistlib
import sys

bundle = Path(sys.argv[1])
expected = sys.argv[2]
info = bundle / "Info.plist"
if not info.exists():
    info = bundle / "Contents" / "Info.plist"
values = plistlib.loads(info.read_bytes())
assert values["CFBundleIdentifier"] == expected, (info, values["CFBundleIdentifier"])
assert values["VaultAppGroup"] == "group.com.statemachine.mindmachine"
assert values["VaultCloudContainer"] == "iCloud.com.statemachine.mindmachine"
key_group = values["VaultKeychainGroup"]
assert "$(" not in key_group and key_group.endswith("com.statemachine.mindmachine"), key_group
print(f"MM_BUNDLE {expected}: resolved App Group, CloudKit and Keychain identifiers PASS")
