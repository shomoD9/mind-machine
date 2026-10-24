#!/usr/bin/env python3
"""Rerun PillSelfTest's capture baseline on a built Mac app, including cold opens.
Called manually as documented in docs/verification/markdown-editor-baseline.md.
The existing native-ci self-test records warm/typing samples without this script.
Only synthetic throwaway-vault measurements and child logs enter the output folder.
"""
import argparse
import json
import math
from pathlib import Path
import platform
import subprocess
import time


def distribution(samples, budget_ms):
    """Use the same nearest-rank convention as PillSelfTest; never drop stalls."""
    if not samples or any(not math.isfinite(value) or value < 0 for value in samples):
        raise ValueError("Missing or invalid cold-open measurements")
    ordered = sorted(samples)
    percentile = lambda rank: ordered[math.ceil(len(ordered) * rank) - 1]
    return {"count": len(samples), "samplesMs": samples,
            "p50Ms": percentile(.50), "p95Ms": percentile(.95), "p99Ms": percentile(.99),
            "maxMs": ordered[-1], "p95BudgetMs": budget_ms,
            "withinP95Budget": percentile(.95) <= budget_ms}


def probe(binary, destination, cold):
    """Wait for each process to exit; launch timing includes loader/AppKit setup.

    macOS Python monotonic and ProcessInfo.systemUptime both use time since boot.
    Reject incompatible clock epochs rather than publishing a negative duration.
    The child samples readiness before waiting for its open animation to settle.
    """
    arguments = [str(binary), "--pill-selftest", str(destination),
                 "--capture-baseline-cold" if cold else "--capture-baseline-only"]
    with destination.with_suffix(".log").open("w") as log:
        launched = time.monotonic()
        # Full Release research counts are deliberately outside CI's 120-second
        # smoke-test deadline. Keep cold-child failures bounded separately.
        subprocess.run(arguments, stdout=log, stderr=subprocess.STDOUT, check=True,
                       timeout=30 if cold else 1800)
    report = json.loads(destination.read_text())
    if report["failed"] or not report["captureBaseline"]["textKit2Throughout"]:
        raise ValueError("Capture input or TextKit 2 correctness check failed; inspect child report")
    baseline = report["captureBaseline"]
    if cold:
        entry = baseline["processEntryUptimeSeconds"]
        ready = baseline["readyUptimeSeconds"]
        if not launched <= entry <= ready <= time.monotonic():
            raise ValueError("Incompatible monotonic clocks; cold launch measurement unavailable")
        return (ready - launched) * 1000
    return baseline


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Built MindMachineMac.app (prefer Release)")
    parser.add_argument("output", type=Path, help="Writable results directory (see sandbox note in docs)")
    parser.add_argument("--cold-opens", type=int, default=30)
    args = parser.parse_args()
    if platform.system() != "Darwin":
        parser.error("AppKit measurements require macOS")
    if args.cold_opens < 1:
        parser.error("--cold-opens must be positive")
    binary = args.app.resolve() / "Contents/MacOS/MindMachineMac"
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    # Each child gets the existing isolated self-test vault and defaults suite.
    # Cold means a terminated process; filesystem/OS caches are not purged.
    samples = [probe(binary, args.output / f"cold-{index:02d}.json", True)
               for index in range(args.cold_opens)]
    baseline = probe(binary, args.output / "warm-and-typing.json", False)
    result = {"coldLaunchToInput": distribution(samples, 500), "warmAndTyping": baseline}
    destination = args.output / "baseline.json"
    destination.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"Measured {len(samples)} cold opens; full report: {destination}")
    print(json.dumps({key: value for key, value in result["coldLaunchToInput"].items()
                      if key != "samplesMs"}, sort_keys=True))


if __name__ == "__main__":
    main()
