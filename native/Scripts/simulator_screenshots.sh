#!/usr/bin/env bash
# Renders the iPhone companion, its vault screen and the Mind Machine keyboard in an iOS Simulator,
# in light and dark appearance, and writes PNGs for review. Called by .github/workflows/native-ci.yml
# (ios-build job, "Simulator screenshots") after an ad-hoc-signed Debug simulator build; it is a visual
# check only and asserts nothing. The companion's Debug-only launch arguments (-open-vault,
# -focus-host-composer, in Apps/iOS/MindMachineApp.swift) reach each screen without taps.
#
# Usage: simulator_screenshots.sh <path to MindMachine.app> <output directory>
set -uo pipefail
APP="$1"
OUT="$2"
BUNDLE=com.statemachine.mindmachine
KEYBOARD=com.statemachine.mindmachine.keyboard
mkdir -p "$OUT"

# Prefer a current mid-size iPhone on the newest installed iOS runtime.
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
runtimes = sorted((r for r in devices if "iOS" in r), key=lambda r: [int(p) for p in r.rsplit("iOS-", 1)[-1].split("-") if p.isdigit()])
for runtime in reversed(runtimes):
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone")]
    for wanted in ("iPhone 17 Pro", "iPhone 17", "iPhone 16 Pro", "iPhone 16"):
        match = [d for d in phones if d["name"] == wanted]
        if match:
            print(match[0]["udid"]); sys.exit()
    if phones:
        print(phones[0]["udid"]); sys.exit()
')
if [ -z "$UDID" ]; then echo "No iPhone simulator available"; exit 1; fi
echo "Simulator: $UDID"
xcrun simctl boot "$UDID" 2>/dev/null
xcrun simctl bootstatus "$UDID" -b

# Enable the custom keyboard first in the keyboard list, then reboot so the keyboard daemon reads it.
xcrun simctl install "$UDID" "$APP"
xcrun simctl spawn "$UDID" defaults write -g AppleKeyboards -array "$KEYBOARD" "en_US@sw=QWERTY;hw=Automatic"
xcrun simctl spawn "$UDID" defaults write -g AppleKeyboardsExpanded -int 1
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null

shoot() {
    local name="$1"; shift
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
    xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
    sleep 7
    xcrun simctl io "$UDID" screenshot "$OUT/$name.png" && echo "Wrote $name.png"
}

for appearance in light dark; do
    xcrun simctl ui "$UDID" appearance "$appearance"
    shoot "companion-$appearance"
    shoot "vault-$appearance" -open-vault
    shoot "keyboard-$appearance" -focus-host-composer
done
xcrun simctl shutdown "$UDID"
ls -la "$OUT"
