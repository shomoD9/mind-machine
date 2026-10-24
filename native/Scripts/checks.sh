#!/usr/bin/env bash
# Deterministic native gates, invoked by core-checks CI and documented in
# docs/CHECKS.md. All data is synthetic; Xcode builds are unsigned. --extended
# expands the model bound and liveness checks for a manual or nightly run.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
MODE="${1:-push}"
[ "$MODE" = push ] || [ "$MODE" = --extended ] || { echo 'usage: checks.sh [--extended]'; exit 2; }
BUILD="${MM_CHECKS_BUILD_DIR:-$ROOT/.build-checks}"
mkdir -p "$BUILD"

# No lint/format tool is configured in this repository. Keep the existing
# whitespace gate without installing or inventing a formatting policy.
echo 'GATE 1: tracked diff whitespace (no configured Swift formatter/linter)'
git diff --check
git show --format= --check HEAD

# Reject workflow trust regressions before paying for Swift builds.
echo 'GATE 2: workflow trust rules and factory regressions'
python3 factory/check_workflows.py
python3 -m unittest discover -s factory -p 'test_*.py'

echo 'GATE 3: public package invariants'
swift test --package-path native
swift test --package-path native/Pill

echo 'GATE 4: model safety and counterexample sensitivity'
if command -v java >/dev/null && java -version >/dev/null 2>&1; then
  if [ "$MODE" = --extended ]; then
    spec/run-tlc.sh
  else
    spec/run-tlc.sh projection-safe projection-broken-delete ci-safe broken-ack-early shipped-NoDuplicateCopies-causal \
      shipped-DeleteSparesOtherCopies-causal shipped-DeleteSparesUnseenEdits shipped-NoStaleCopyBesideNewer
  fi
else
  echo 'SKIP TLC: install Java 17+; CI provisions Java 21. Swift regressions above still run.'
fi

echo 'GATE 5: Release query/save budgets and process durability'
swift test -c release --package-path native --filter SearchPerformanceTests
BIN="$(swift build -c release --package-path native --show-bin-path)"
python3 native/Scripts/verify_vault_processes.py "$BIN/VaultIntegrityProbe"
PERF="$(mktemp -d)"
trap 'rm -rf "$PERF"' EXIT
"$BIN/VaultIntegrityProbe" seed "$PERF/seed/vault.json"
for round in 1 2 3; do
  mkdir "$PERF/$round"
  cp "$PERF/seed/vault.sqlite" "$PERF/$round/vault.sqlite"
  "$BIN/VaultIntegrityProbe" benchmark-keyboard "$PERF/$round/vault.json" | tee -a "$PERF/measurements.txt"
done
# Bound medians from fresh processes, rather than substituting test-runner RSS
# for extension memory or allowing a single scheduler pause to dominate a gate.
python3 - "$PERF/measurements.txt" <<'PY'
import json
from pathlib import Path
from statistics import median
import sys
samples = [json.loads(line.split('MM_KEYBOARD_CORE ', 1)[1]) for line in Path(sys.argv[1]).read_text().splitlines() if 'MM_KEYBOARD_CORE ' in line]
assert len(samples) == 3, 'Expected three independent fresh-process samples'
budgets = {'cold_snapshot_ms': 100, 'first_recall_ms': 20, 'append_p95_ms': 12, 'peak_rss_mib': 16}
for name, budget in budgets.items():
    measured = median(sample[name] for sample in samples)
    print(f'MM_CORE_BUDGET {name} median={measured:.3f} budget={budget}')
    assert 0 < measured < budget, (name, measured, budget)
PY

echo 'GATE 6: unsigned bundles and requested entitlements'
xcodebuild -quiet -project native/MindMachine.xcodeproj -scheme MindMachine \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$BUILD/ios" CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/MindMachine.xcodeproj -scheme MindMachineMac \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$BUILD/mac" CODE_SIGNING_ALLOWED=NO build
IOS="$BUILD/ios/Build/Products/Debug-iphonesimulator/MindMachine.app"
python3 native/Scripts/verify_bundle_configuration.py "$IOS" com.statemachine.mindmachine --entitlements native/Apps/iOS/Vault.entitlements
python3 native/Scripts/verify_bundle_configuration.py "$IOS/PlugIns/MindMachineKeyboard.appex" com.statemachine.mindmachine.keyboard --entitlements native/Apps/Keyboard/Vault.entitlements
python3 native/Scripts/verify_bundle_configuration.py "$BUILD/mac/Build/Products/Debug/MindMachineMac.app" com.statemachine.mindmachine --entitlements native/Apps/Mac/Vault.entitlements
echo 'MM_CHECKS all selected gates PASS'
