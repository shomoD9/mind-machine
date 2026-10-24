#!/usr/bin/env python3
"""Poll coding jobs without model calls; invoked by cron or --watch, tested in tools/tests.

Only state-change metadata goes to stdout. Logs, result prose, session contents,
process arguments and relaunch output are never forwarded to the caller.
"""

import argparse
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time


TERMINAL = {"EXITED_OK", "BLOCKED"}
STATES = TERMINAL | {"STARTING", "RUNNING", "STALLED", "DIED"}


def last_status(path):
    """Inspect only the last nonblank line, bounding reads of growing result files."""
    try:
        with path.open("rb") as stream:
            stream.seek(0, os.SEEK_END)
            stream.seek(max(0, stream.tell() - 8192))
            lines = stream.read().splitlines()
        last = next((line.strip() for line in reversed(lines) if line.strip()), b"")
    except FileNotFoundError:
        return None
    if last == b"STATUS: DONE":
        return "EXITED_OK"
    if last == b"STATUS: BLOCKED" or last.startswith(b"STATUS: BLOCKED "):
        return "BLOCKED"
    return None


def modified(path, fallback):
    """Missing heartbeat files receive the launch grace period, then age normally."""
    try:
        return path.stat().st_mtime
    except FileNotFoundError:
        return fallback


def process_alive(config):
    """Check a PID or literal command substring; ignore zombies and this observer."""
    if "pid_file" in config:
        try:
            pid = int(Path(config["pid_file"]).read_text().strip())
        except (FileNotFoundError, ValueError):
            return False
        if pid <= 1:
            return False
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        # Linux kill(0) also succeeds for an exited, unreaped child.
        stat = Path(f"/proc/{pid}/stat")
        try:
            return stat.read_text().rsplit(")", 1)[1].split()[0] != "Z"
        except FileNotFoundError:
            # macOS has no /proc; ps supplies the same zombie check.
            result = subprocess.run(["ps", "-p", str(pid), "-o", "stat="],
                                    capture_output=True, text=True, check=False)
            return bool(result.stdout.strip()) and not result.stdout.lstrip().startswith("Z")
    result = subprocess.run(["ps", "-eo", "pid=,stat=,args="],
                            capture_output=True, text=True, check=True)
    for line in result.stdout.splitlines():
        fields = line.strip().split(None, 2)
        if len(fields) == 3 and int(fields[0]) != os.getpid() and not fields[1].startswith("Z"):
            if config["process_match"] in fields[2]:
                return True
    return False


def relaunch(config):
    """Run one trusted argv command detached; its wrapper must update the PID file."""
    subprocess.Popen(config["relaunch"], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True)


def save_state(path, state):
    """Atomic replacement keeps a killed observer from leaving half-written JSON."""
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("w", encoding="utf-8") as stream:
        json.dump(state, stream, sort_keys=True)
        stream.write("\n")
    temporary.replace(path)


def poll(config, state_path, *, now=None, alive=process_alive, launch=relaunch):
    """Persist a single observation and return an event only when the state changes."""
    now = time.time() if now is None else now
    try:
        previous = json.loads(state_path.read_text())
    except FileNotFoundError:
        previous = {}
    if previous and previous["name"] != config["name"]:
        raise ValueError("state belongs to another job")
    if previous and (previous["state"] not in STATES or previous["relaunches"] not in (0, 1)):
        raise ValueError("invalid persisted state")
    state = dict(previous) or {"name": config["name"], "started_at": now, "relaunches": 0}
    old = previous.get("state")

    # A final result wins over liveness, including the interval before a wrapper exits.
    # Terminal states stay quiet if the caller later archives or removes the result.
    final = last_status(Path(config["result_path"]))
    if old in TERMINAL:
        current = old
    elif final:
        current = final
    elif not previous:
        current = "STARTING"
    elif alive(config):
        state.pop("awaiting_relaunch", None)
        newest = max(modified(Path(config["log_path"]), state["started_at"]),
                     modified(Path(config["session_path"]), state["started_at"]),
                     state["started_at"])
        current = "STALLED" if now - newest >= config["stall_minutes"] * 60 else "RUNNING"
    elif (old == "STARTING" or state.get("awaiting_relaunch")) and now - state["started_at"] < config["startup_seconds"]:
        current = "STARTING"
    else:
        current = "DIED"
        state.pop("awaiting_relaunch", None)

    state["state"] = current
    changed = current != old
    if changed:
        state["changed_at"] = now
    # Reserve the sole attempt durably BEFORE running anything. Restart only dead
    # jobs: spawning over a live stalled writer would duplicate work and commits.
    should_launch = current == "DIED" and state["relaunches"] == 0 and config.get("relaunch")
    if should_launch:
        state["relaunches"] = 1
        state["started_at"] = now
        state["awaiting_relaunch"] = True
    save_state(state_path, state)
    if should_launch:
        try:
            launch(config)
        except OSError:
            # A failed command consumes the attempt; the next poll cannot loop it.
            pass
    if changed:
        return {"name": config["name"], "state": current, "previous": old,
                "changed_at": now, "relaunches": state["relaunches"]}
    return None


def load_config(path):
    """Require a per-job session path so unrelated sessions cannot mask a stall."""
    config = json.loads(path.read_text())
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", config["name"]):
        raise ValueError("invalid name")
    for key in ("log_path", "result_path", "session_path"):
        config[key] = str(Path(config[key]).expanduser().resolve())
    if ("pid_file" in config) == ("process_match" in config):
        raise ValueError("choose one process source")
    if "pid_file" in config:
        config["pid_file"] = str(Path(config["pid_file"]).expanduser().resolve())
    elif not isinstance(config["process_match"], str) or not config["process_match"].strip():
        raise ValueError("empty process match")
    config.setdefault("stall_minutes", 10)
    config.setdefault("startup_seconds", 60)
    for key in ("stall_minutes", "startup_seconds"):
        if not isinstance(config[key], (float, int)) or not math.isfinite(config[key]) or config[key] <= 0:
            raise ValueError("invalid time limit")
    if "relaunch" in config:
        command = config["relaunch"]
        if not isinstance(command, list) or not command or not all(isinstance(arg, str) and arg for arg in command):
            raise ValueError("relaunch must be argv")
    return config


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--interval", type=float, default=30)
    args = parser.parse_args()
    try:
        if not math.isfinite(args.interval) or args.interval <= 0:
            raise ValueError("invalid interval")
        config = load_config(args.config)
        # One observer owns a state file. flock also protects the relaunch budget
        # from overlapping cron calls, and releases automatically on process exit.
        import fcntl
        with args.state.with_name(args.state.name + ".lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return 0
            while True:
                event = poll(config, args.state)
                if event:
                    print(json.dumps(event, sort_keys=True), flush=True)
                if not args.watch:
                    return 0
                time.sleep(args.interval)
    except (OSError, ValueError, KeyError, TypeError):
        # Exceptions may contain paths, commands or result contents. Keep errors fixed.
        print("watchdog: invalid config/state or unavailable file/process source", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
