#!/usr/bin/env bash
# Builds the before/after production core on the same macOS runner and drives
# both with the current public-API process probe. core-checks CI calls this;
# synthetic vaults and all measurements stay inside a disposable directory.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BEFORE="${1:-7ac950e}"
WORK="$(mktemp -d)"
cleanup() { git -C "$ROOT" worktree remove --force "$WORK/before" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT
git -C "$ROOT" worktree add --detach "$WORK/before" "$BEFORE"
# Use identical benchmark instrumentation against each implementation. The new
# window test must reproduce the newest-source eviction on the old model.
cp "$ROOT/native/Sources/VaultIntegrityProbe/main.swift" "$WORK/before/native/Sources/VaultIntegrityProbe/main.swift"
cp "$ROOT/native/Tests/MindMachineUITests/WorkspaceTests.swift" "$WORK/before/native/Tests/MindMachineUITests/WorkspaceTests.swift"
if swift test --package-path "$WORK/before/native" --filter testKeyboardSaveAndChecklistEditKeepNewestHundredSources > "$WORK/before-test.log" 2>&1; then
  echo 'Expected the old keyboard model to evict a recent source'; exit 1
fi
grep 'Save must keep the newest older source' "$WORK/before-test.log"
swift build -c release --package-path "$WORK/before/native"
swift build -c release --package-path "$ROOT/native"
BEFORE_BIN="$(swift build -c release --package-path "$WORK/before/native" --show-bin-path)/VaultIntegrityProbe"
AFTER_BIN="$(swift build -c release --package-path "$ROOT/native" --show-bin-path)/VaultIntegrityProbe"
"$BEFORE_BIN" seed "$WORK/seed/vault.json"
# Each fresh probe sees the same closed database bytes. Repeated samples report
# runner variance without hiding a failed budget behind a timing retry.
for round in 1 2 3; do
  for side in before after; do
    mkdir -p "$WORK/$side-$round"
    cp "$WORK/seed/vault.sqlite" "$WORK/$side-$round/vault.sqlite"
    if [ "$side" = before ]; then PROBE="$BEFORE_BIN"; else PROBE="$AFTER_BIN"; fi
    printf '%s round=%s ' "$side" "$round"
    "$PROBE" benchmark-keyboard "$WORK/$side-$round/vault.json"
  done
done
