"""Exercise watchdog transitions with fake liveness and a real temporary filesystem.

Run by fast-core CI and by `python3 -m unittest discover -s tools/tests -v`.
CLI tests also prove that private file/command contents never enter emitted events.
"""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "watchdog.py"
SPEC = importlib.util.spec_from_file_location("watchdog", SCRIPT)
watchdog = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(watchdog)


class WatchdogTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.state = self.root / "state.json"
        self.config = {"name": "fast-job", "pid_file": str(self.root / "pid"),
                       "log_path": str(self.root / "log"),
                       "session_path": str(self.root / "rollout.jsonl"),
                       "result_path": str(self.root / "result.md"),
                       "stall_minutes": 2, "startup_seconds": 10}
        self.live = False
        self.launches = []

    def poll(self, now):
        return watchdog.poll(self.config, self.state, now=now,
                             alive=lambda _: self.live, launch=self.launches.append)

    def heartbeat(self, key, timestamp):
        path = Path(self.config[key])
        path.write_text("private session content")
        os.utime(path, (timestamp, timestamp))

    def start(self):
        self.assertEqual(self.poll(1000)["state"], "STARTING")
        self.live = True
        self.assertEqual(self.poll(1001)["state"], "RUNNING")

    # Two independent heartbeats prevent silent stdout during tool work from
    # waking an agent. Each heartbeat can also recover an already stalled job.
    def test_dual_silence_stalls_and_session_activity_recovers(self):
        self.start()
        self.heartbeat("log_path", 1001)
        self.heartbeat("session_path", 1002)
        self.assertIsNone(self.poll(1121))
        self.assertEqual(self.poll(1122)["state"], "STALLED")
        self.heartbeat("session_path", 1123)
        self.assertEqual(self.poll(1123)["state"], "RUNNING")

    def test_silent_log_with_moving_session_never_stalls(self):
        self.start()
        self.heartbeat("log_path", 1001)
        self.heartbeat("session_path", 1200)
        self.assertIsNone(self.poll(1250))
        self.assertEqual(json.loads(self.state.read_text())["state"], "RUNNING")

    def test_moving_log_with_silent_session_never_stalls(self):
        self.start()
        self.heartbeat("session_path", 1001)
        self.heartbeat("log_path", 1200)
        self.assertIsNone(self.poll(1250))

    def test_missing_heartbeats_age_from_start(self):
        self.start()
        self.assertEqual(self.poll(1120)["state"], "STALLED")
        self.heartbeat("log_path", 1121)
        self.assertEqual(self.poll(1121)["state"], "RUNNING")

    def test_no_repeat_event_in_every_state(self):
        self.assertEqual(self.poll(1000)["state"], "STARTING")
        self.assertIsNone(self.poll(1001))
        self.live = True
        self.assertEqual(self.poll(1002)["state"], "RUNNING")
        self.assertIsNone(self.poll(1003))
        self.assertEqual(self.poll(1120)["state"], "STALLED")
        self.assertIsNone(self.poll(1121))
        self.live = False
        self.assertEqual(self.poll(1122)["state"], "DIED")
        self.assertIsNone(self.poll(1123))

    def test_dead_without_result_and_startup_grace(self):
        self.poll(1000)
        self.assertIsNone(self.poll(1009))
        self.assertEqual(self.poll(1010)["state"], "DIED")

    def test_running_process_death_does_not_receive_startup_grace(self):
        self.start()
        self.live = False
        self.assertEqual(self.poll(1002)["state"], "DIED")
        self.assertIsNone(self.poll(1003))

    def test_results_win_while_alive_or_dead_and_remain_terminal(self):
        for marker, expected in [("DONE", "EXITED_OK"), ("BLOCKED secret-reason", "BLOCKED")]:
            for live in [False, True]:
                with self.subTest(marker=marker, live=live):
                    self.state.unlink(missing_ok=True)
                    Path(self.config["result_path"]).unlink(missing_ok=True)
                    self.start()
                    self.live = live
                    Path(self.config["result_path"]).write_text(f"private notes\nSTATUS: {marker}\n\n")
                    event = self.poll(1300)
                    self.assertEqual(event["state"], expected)
                    self.assertNotIn("secret", json.dumps(event))
                    self.assertIsNone(self.poll(1301))
                    Path(self.config["result_path"]).unlink()
                    self.assertIsNone(self.poll(1302))

    def test_stalled_can_finish_or_die(self):
        for marker, expected in [("DONE", "EXITED_OK"), ("BLOCKED", "BLOCKED"), (None, "DIED")]:
            with self.subTest(marker=marker):
                self.state.unlink(missing_ok=True)
                Path(self.config["result_path"]).unlink(missing_ok=True)
                self.start()
                self.assertEqual(self.poll(1200)["state"], "STALLED")
                if marker:
                    Path(self.config["result_path"]).write_text(f"STATUS: {marker}")
                else:
                    self.live = False
                self.assertEqual(self.poll(1201)["state"], expected)

    def test_only_final_exact_marker_is_accepted(self):
        self.poll(1000)
        for body in ["STATUS: DONE\nstill working", "STATUS: DONE-ish", "STATUS: BLOCKEDNESS"]:
            Path(self.config["result_path"]).write_text(body)
            self.assertIsNone(watchdog.last_status(Path(self.config["result_path"])))
        self.assertEqual(self.poll(1011)["state"], "DIED")

    # Reconstructing from persisted JSON must retain the retry budget even after
    # a command fails. A stalled live process must never get a competing writer.
    def test_relaunch_once_across_polls_and_preserved_in_state(self):
        self.config["relaunch"] = ["/trusted/job-wrapper"]
        self.start()
        self.assertEqual(self.poll(1200)["state"], "STALLED")
        self.assertEqual(self.launches, [])
        self.live = False
        self.assertEqual(self.poll(1201)["state"], "DIED")
        self.assertEqual(len(self.launches), 1)
        self.assertEqual(json.loads(self.state.read_text())["relaunches"], 1)
        self.assertEqual(self.poll(1202)["state"], "STARTING")
        self.live = True
        self.assertEqual(self.poll(1203)["state"], "RUNNING")
        self.live = False
        self.assertEqual(self.poll(1212)["state"], "DIED")
        self.assertIsNone(self.poll(1213))
        self.assertEqual(len(self.launches), 1)

    def test_failed_relaunch_is_not_retried(self):
        self.config["relaunch"] = ["/missing/job-wrapper"]
        self.poll(1000)
        def failed_launch(_):
            raise OSError("private command detail")
        watchdog.poll(self.config, self.state, now=1010, alive=lambda _: False,
                      launch=failed_launch)
        self.poll(1021)
        self.assertEqual(self.launches, [])
        self.assertEqual(json.loads(self.state.read_text())["relaunches"], 1)

    def test_pid_file_missing_invalid_gone_and_alive(self):
        pid_file = Path(self.config["pid_file"])
        for content in [None, "private-invalid", "-1", "0", "1"]:
            if content is not None:
                pid_file.write_text(content)
            self.assertFalse(watchdog.process_alive(self.config))
        pid_file.write_text(str(os.getpid()))
        self.assertTrue(watchdog.process_alive(self.config))
        with patch.object(os, "kill", side_effect=ProcessLookupError):
            self.assertFalse(watchdog.process_alive(self.config))
        with patch.object(os, "kill", side_effect=PermissionError):
            self.assertTrue(watchdog.process_alive(self.config))

    def test_process_match_excludes_zombie_and_observer(self):
        self.config.pop("pid_file")
        self.config["process_match"] = "job-secret-argv"
        def result(rows):
            return subprocess.CompletedProcess([], 0, rows)
        with patch.object(subprocess, "run", return_value=result(
                f"{os.getpid()} S job-secret-argv\n999 Z job-secret-argv\n")):
            self.assertFalse(watchdog.process_alive(self.config))
        with patch.object(subprocess, "run", return_value=result("888 S job-secret-argv\n")):
            self.assertTrue(watchdog.process_alive(self.config))

    def test_cli_events_are_private_and_persist_between_invocations(self):
        config_path = self.root / "config.json"
        config_path.write_text(json.dumps(self.config))
        command = [sys.executable, str(SCRIPT), str(config_path), "--state", str(self.state)]
        first = subprocess.run(command, capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(first.stdout)["state"], "STARTING")
        self.assertNotIn("path", first.stdout)
        self.assertEqual(first.stderr, "")
        second = subprocess.run(command, capture_output=True, text=True, check=True)
        self.assertEqual(second.stdout, "")
        Path(self.config["result_path"]).write_text("secret=never-print\nSTATUS: BLOCKED private-reason")
        final = subprocess.run(command, capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(final.stdout)["state"], "BLOCKED")
        self.assertNotIn("private", final.stdout)
        config_path.write_text('{"secret=never-print": "bad"}')
        invalid = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(invalid.returncode, 2)
        self.assertNotIn("secret", invalid.stderr)

    def test_corrupt_state_cannot_leak_private_values_in_previous_event(self):
        config_path = self.root / "config.json"
        config_path.write_text(json.dumps(self.config))
        self.state.write_text(json.dumps({"name": self.config["name"],
                                          "state": "private-state-secret", "relaunches": 0}))
        result = subprocess.run([sys.executable, str(SCRIPT), str(config_path),
                                 "--state", str(self.state)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("secret", result.stderr)

    def test_overlapping_cli_observer_does_not_write_or_emit(self):
        import fcntl
        config_path = self.root / "config.json"
        config_path.write_text(json.dumps(self.config))
        with self.state.with_name(self.state.name + ".lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = subprocess.run([sys.executable, str(SCRIPT), str(config_path),
                                     "--state", str(self.state)], capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout, "")
        self.assertFalse(self.state.exists())


if __name__ == "__main__":
    unittest.main()
