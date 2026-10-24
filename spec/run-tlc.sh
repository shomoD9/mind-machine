#!/usr/bin/env bash
# What this does: runs TLC on spec/MindMachineSync.tla once per *.cfg and compares each result with the
# "\* expect:" line at the top of that config. Exit 0 means every config behaved as expected.
# Who calls it: people and agents changing sync or shared-vault code (see
# .agents/skills/verify-mindmachine-sync/SKILL.md) and, once added, a CI job on a Linux runner.
# Tools: Java 17+ and tla2tools.jar 1.7.4. Set JAVA and TLA2TOOLS, or let this script download both to
# ~/.local/mm-tla (the jar is checked against the SHA-256 below). Usage: spec/run-tlc.sh [config-name ...]
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS="${MM_TLA_HOME:-$HOME/.local/mm-tla}"
JAR_SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"   # tla2tools.jar v1.7.4
JAR_URL="https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar"

# Find or fetch the tools.
JAR="${TLA2TOOLS:-$TOOLS/tla2tools.jar}"
if [ ! -f "$JAR" ]; then
  mkdir -p "$TOOLS" && curl -sL -o "$JAR" "$JAR_URL" || { echo "Cannot download tla2tools.jar"; exit 2; }
fi
echo "$JAR_SHA256  $JAR" | sha256sum -c --quiet - 2>/dev/null || shasum -a 256 -c --quiet <<<"$JAR_SHA256  $JAR" \
  || { echo "tla2tools.jar does not match the pinned SHA-256"; exit 2; }
JAVA_BIN="${JAVA:-$(command -v java || true)}"
[ -z "$JAVA_BIN" ] && [ -x "$TOOLS/jdk/bin/java" ] && JAVA_BIN="$TOOLS/jdk/bin/java"
[ -z "$JAVA_BIN" ] && { echo "No java found. Install Java 17+ (for example Temurin 21) or set JAVA."; exit 2; }

if [ $# -gt 0 ]; then CONFIGS=("$@"); else CONFIGS=($(cd "$HERE" && ls *.cfg | sed 's/\.cfg$//')); fi
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
status=0
for name in "${CONFIGS[@]}"; do
  expect="$(sed -n 's/^\\\* expect: //p' "$HERE/$name.cfg" | head -1)"
  start=$(date +%s)
  "$JAVA_BIN" -XX:+UseParallelGC -Djava.io.tmpdir="$WORK" -cp "$JAR" tlc2.TLC -workers auto \
      -metadir "$WORK/$name" -config "$HERE/$name.cfg" "$HERE/MindMachineSync.tla" > "$WORK/$name.out" 2>&1
  code=$?
  # TLC exit codes: 0 no error, 12 safety violation, 13 liveness violation, other = tool error.
  case "$code" in
    0)  got="pass" ;;
    12) got="violation: $(sed -n 's/^Error: Invariant \(.*\) is violated.*/\1/p' "$WORK/$name.out" | head -1)" ;;
    13) got="violation: $(sed -n 's/^Error: Temporal properties were violated.*/liveness/p' "$WORK/$name.out" | head -1)" ;;
    *)  got="tool error (exit $code)" ;;
  esac
  # A liveness failure does not name the property; the config's expect line does.
  if [ "$code" = 13 ] && [[ "$expect" == violation:* ]]; then got="$expect"; fi
  if [ "$got" = "$expect" ]; then verdict="ok  "; else verdict="FAIL"; status=1; fi
  printf '%s %-40s expected [%s] got [%s] (%ss)\n' "$verdict" "$name" "$expect" "$got" "$(( $(date +%s) - start ))"
  if [ "$verdict" = "FAIL" ] || [ -n "${MM_TLC_SHOW:-}" ]; then sed -n '/^Error:/,/^[0-9]* states generated/p' "$WORK/$name.out" | head -80; fi
done
exit $status
