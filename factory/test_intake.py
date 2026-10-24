#!/usr/bin/env python3
# Fixture regressions for the base-owned intake, artifact consumer and workflow
# guard. Run by checks.sh via unittest discovery; includes a killed mutant.
import base64
import io
import json
from pathlib import Path
import os
import unittest
from unittest import mock
import zipfile

import check_workflows
import gate
import intake

CONFIG = json.loads(Path(__file__).with_name("lanes.json").read_text())
REPO = "shomoD9/mind-machine"


def fixture(paths=("docs/FACTORY.md",), association="NONE", body="Refs #123"):
    pr = {"number": 7, "body": body, "title": "fixture", "author_association": association,
          "user": {"login": "stranger", "type": "User"}, "changed_files": len(paths),
          "additions": 10, "deletions": 2, "state": "open", "labels": [],
          "head": {"sha": "a" * 40, "ref": "topic", "repo": {"full_name": "stranger/fork"}},
          "base": {"sha": "b" * 40, "repo": {"full_name": REPO}}}
    files = [{"filename": path, "patch": "@@ -1 +1 @@\n-old\n+new"} for path in paths]
    return pr, files


def result(pr=None, files=None):
    if pr is None:
        pr, files = fixture()
    return {**intake.classify(pr, files, CONFIG, REPO), "run_id": 99, "run_attempt": 1}


def run_fixture(pr):
    return {"id": 99, "run_attempt": 1, "repository": {"full_name": REPO},
            "event": "pull_request", "conclusion": "success", "path": ".github/workflows/pr-intake.yml",
            "head_sha": pr["head"]["sha"], "head_repository": pr["head"]["repo"],
            "head_branch": pr["head"]["ref"], "pull_requests": []}


class IntakeRules(unittest.TestCase):
    def classify(self, paths, association="NONE", body="Refs #123"):
        pr, files = fixture(paths, association, body)
        return intake.classify(pr, files, CONFIG, REPO)

    def test_docs_translations_and_tests_only_are_lane_a(self):
        for path in ("docs/FACTORY.md", "README.md", "native/Tests/XTests.swift", "native/Pill/Tests/X.swift", "native/UI/en.lproj/Localizable.strings"):
            with self.subTest(path=path):
                self.assertEqual(self.classify([path])["verdict"], "PASS")

    def test_unknown_code_is_routed_instead_of_auto_passing(self):
        self.assertEqual(self.classify(["new/module.swift"])["lane"], "B")

    def test_core_logic_routes_b_but_sync_storage_and_state_route_c(self):
        self.assertEqual(self.classify(["native/Sources/MindMachineCore/ProcessMemory.swift"])["lane"], "B")
        for path in ("spec/fixed-safe.cfg", ".scratch/native-mvp/spec.md", "native/Sources/MindMachineCore/VaultFile.swift", "native/Pill/Sources/MindMachinePill/PillState.swift"):
            with self.subTest(path=path):
                value = self.classify([path])
                self.assertEqual((value["lane"], value["verdict"]), ("C", "ROUTE"))

    def test_outsider_lane_d_plus_docs_takes_strictest_lane(self):
        value = self.classify([".github/workflows/x.yml", "docs/x.md"])
        self.assertEqual((value["lane"], value["reasons"]), ("D", ["LANE_D_OUTSIDER"]))

    def test_traversal_is_normalized_before_protected_path_match(self):
        self.assertEqual(intake.lane_for("a/../.github/x", CONFIG), "D")

    def test_repo_escape_absolute_and_backslash_paths_fail_closed(self):
        for path in ("../x", "/x", "a/../../x", "a\\b"):
            with self.subTest(path=path):
                self.assertIn("INVALID_PATH", self.classify([path])["reasons"])

    def test_renaming_protected_old_path_to_docs_still_rejects(self):
        pr, files = fixture()
        files[0]["previous_filename"] = ".github/workflows/release.yml"
        self.assertIn("LANE_D_OUTSIDER", result(pr, files)["reasons"])

    def test_deleting_build_and_dependency_files_is_protected(self):
        for path in ("native/Package.swift", "native/Package.resolved", "native/Scripts/a.py", "spec/run-tlc.sh", "native/Apps/iOS/Info.plist", "native/Apps/Mac/Vault.entitlements", "factory/intake.py"):
            with self.subTest(path=path):
                self.assertEqual(self.classify([path])["lane"], "D")

    def test_sensitive_network_and_full_access_edits_in_shared_code_are_d(self):
        for text in ("URLSession.shared", "hasFullAccess", "RequestsOpenAccess", "import Network"):
            pr, files = fixture(["native/Sources/Shared.swift"])
            files[0]["patch"] = "@@ -1 +1 @@\n-" + text
            self.assertEqual(result(pr, files)["lane"], "D")

    def test_docs_and_test_fixtures_can_quote_network_and_full_access_apis(self):
        for path in ("docs/network.md", "native/Tests/PrivacyTests.swift"):
            pr, files = fixture([path])
            files[0]["patch"] = "@@ -1 +1 @@\n+URLSession RequestsOpenAccess Full Access"
            self.assertEqual(result(pr, files)["lane"], "A")
        pr, files = fixture(["native/Tests/RenamedTests.swift"])
        files[0].pop("patch")
        self.assertEqual(result(pr, files)["lane"], "A")

    def test_missing_swift_patch_cannot_hide_network_change(self):
        pr, files = fixture(["native/Sources/Shared.swift"])
        del files[0]["patch"]
        self.assertEqual(result(pr, files)["lane"], "D")

    def test_huge_diff_and_file_count_enforce_configurable_budgets(self):
        for key, amount in (("additions", 1001), ("changed_files", 101)):
            pr, files = fixture()
            pr[key] = amount
            self.assertIn("SIZE_LIMIT", result(pr, files)["reasons"])
        config = {**CONFIG, "max_changed_lines": 12}
        pr, files = fixture()
        self.assertEqual(intake.classify(pr, files, config, REPO)["verdict"], "PASS")

    def test_incomplete_api_file_list_cannot_hide_lane_d(self):
        pr, files = fixture()
        pr["changed_files"] += 1
        self.assertIn("FILES_INCOMPLETE", result(pr, files)["reasons"])

    def test_outsiders_need_issue_reference_in_body(self):
        for body in (None, "No issue", "Fixes #0", "https://github.com/other/repo/issues/12"):
            with self.subTest(body=body):
                self.assertIn("ISSUE_REQUIRED", self.classify(["docs/x.md"], body=body)["reasons"])
        for body in ("Fixes #1", f"https://github.com/{REPO}/issues/12"):
            self.assertEqual(self.classify(["docs/x.md"], body=body)["verdict"], "PASS")

    def test_owner_member_collaborator_bypass_only_outsider_rules(self):
        for role in intake.TRUSTED:
            value = self.classify(["factory/intake.py"], association=role, body=None)
            self.assertEqual((value["lane"], value["label"], value["verdict"]), ("D", "lane-d", "ROUTE"))
        pr, files = fixture(association="OWNER", body=None)
        pr["additions"] = 1001
        self.assertEqual(result(pr, files)["reasons"], ["SIZE_LIMIT"])

    def test_only_exact_configured_factory_bot_has_trust(self):
        pr, files = fixture(["factory/intake.py"], body=None)
        pr["user"] = {"login": "github-actions[bot]", "type": "Bot"}
        self.assertEqual(result(pr, files)["verdict"], "ROUTE")
        pr["user"]["login"] = "other[bot]"
        self.assertEqual(result(pr, files)["verdict"], "REJECT")

    def test_title_body_branch_metacharacters_never_reach_shell(self):
        pr, files = fixture()
        payload = "$(touch /tmp/factory-injection); `id` '${{ secrets.X }}'"
        pr["title"] = pr["head"]["ref"] = payload
        pr["body"] += "\n" + payload
        with mock.patch("intake.subprocess.run") as execute:
            self.assertEqual(result(pr, files)["verdict"], "PASS")
            execute.assert_not_called()
        with mock.patch("intake.subprocess.run", return_value=mock.Mock(stdout=b'{}')) as execute:
            intake.api("repos/a/b/pulls/1", "POST", {"body": payload})
            args, kwargs = execute.call_args
            self.assertIsInstance(args[0], list)
            self.assertNotIn("shell", kwargs)
            self.assertNotIn(payload, args[0])
            self.assertEqual(json.loads(kwargs["input"])["body"], payload)

    def test_mutant_without_normalization_is_killed_by_real_rule_test(self):
        def broken_matcher(path, config):
            matches = [rule["lane"] for rule in config["rules"] if any(intake.fnmatch.fnmatchcase(path, p) for p in rule["paths"])]
            return max(matches, default=config["default_lane"])
        suite = unittest.TestSuite([IntakeRules("test_traversal_is_normalized_before_protected_path_match")])
        output = io.StringIO()
        with mock.patch.object(intake, "lane_for", broken_matcher):
            report = unittest.TextTestRunner(stream=output).run(suite)
        self.assertEqual(len(report.failures), 1)
        self.assertFalse(report.errors)
        self.assertIn("'B' != 'D'", output.getvalue())


class ArtifactRules(unittest.TestCase):
    def test_closed_schema_rejects_injected_fields_types_labels_and_verdicts(self):
        self.assertEqual(gate.validate(result())["lane"], "A")
        for key, value in (("command", "id"), ("pr_number", True), ("schema_version", True), ("head_sha", "main"), ("label", "lane-d"), ("lane", "AB"), ("verdict", "REJECT"), ("reasons", ["RUN_SHELL"]), ("size", {"files": -1, "lines": 2})):
            data = result()
            data[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                gate.validate(data)

    def test_zip_slip_extra_files_bombs_and_duplicate_keys_are_rejected(self):
        for name, text in (("../intake.json", "{}"), ("intake.json", "x" * 16385), ("intake.json", '{"lane":"A","lane":"D"}')):
            blob = io.BytesIO()
            with zipfile.ZipFile(blob, "w", compression=zipfile.ZIP_DEFLATED) as archive:
                archive.writestr(name, text)
            with self.subTest(name=name), self.assertRaises(ValueError):
                gate.read_artifact(blob.getvalue())
        blob = io.BytesIO()
        with zipfile.ZipFile(blob, "w") as archive:
            archive.writestr("intake.json", json.dumps(result()))
        self.assertEqual(gate.read_artifact(blob.getvalue()), result())

    def test_fork_empty_run_pr_list_is_bound_to_current_head_repository_and_branch(self):
        pr, files = fixture()
        gate.bind_result(result(pr, files), run_fixture(pr), pr, REPO)
        for key, value in (("head_sha", "c" * 40), ("run_attempt", 2), ("head_branch", "other"), ("path", ".github/workflows/evil.yml"), ("pull_requests", [{"number": 123}])):
            run = run_fixture(pr)
            run[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                gate.bind_result(result(pr, files), run, pr, REPO)

    def test_body_edit_without_head_change_invalidates_old_rejection(self):
        pr, files = fixture(body=None)
        data, run = result(pr, files), run_fixture(pr)
        pr["body"] = "Refs #123"
        with self.assertRaises(ValueError):
            gate.bind_result(data, run, pr, REPO)


    def exercise_gate(self, verdict="REJECT", tampered=False):
        # Drive the complete trusted entrypoint against API fixtures, including
        # provenance and artifact download. Every outgoing write is recorded.
        pr, files = fixture(["factory/intake.py"] if verdict == "REJECT" else ["spec/fixed-safe.cfg"])
        data = result(pr, files)
        run = run_fixture(pr)
        blob = io.BytesIO()
        with zipfile.ZipFile(blob, "w") as archive:
            archive.writestr("intake.json", json.dumps(data))
        producer = b"trusted producer workflow"
        writes = []

        def fake_api(endpoint, method="GET", payload=None, raw=False):
            if method != "GET":
                writes.append((endpoint, method, payload))
                return {}
            if endpoint.endswith("/actions/runs/99"):
                return run
            if "/artifacts?" in endpoint:
                return {"artifacts": [{"id": 5, "name": "pr-intake", "expired": False, "size_in_bytes": len(blob.getvalue())}]}
            if endpoint.endswith("/artifacts/5/zip"):
                return blob.getvalue()
            if endpoint.endswith("/pulls/7"):
                return pr
            if "/contents/" in endpoint:
                content = b"forged producer" if tampered else producer
                return {"content": base64.b64encode(content).decode()}
            if "/labels?" in endpoint:
                return [{"name": data["label"]}]
            self.fail("unexpected API route: " + endpoint)

        def fake_path(value):
            return mock.Mock(read_text=lambda: json.dumps({"workflow_run": {"id": 99}}), read_bytes=lambda: producer)

        with mock.patch.dict(os.environ, {"GITHUB_EVENT_PATH": "event.json", "GITHUB_REPOSITORY": REPO}), mock.patch.object(gate, "api", fake_api), mock.patch.object(gate, "Path", fake_path), mock.patch("builtins.print"):
            if tampered:
                with self.assertRaisesRegex(ValueError, "producer workflow changed"):
                    gate.main()
            else:
                gate.main()
        return writes

    def test_tampered_producer_cannot_authorize_any_label_comment_or_close(self):
        self.assertEqual(self.exercise_gate(tampered=True), [])

    def test_valid_rejection_labels_comments_exact_reason_and_closes_without_merge(self):
        writes = self.exercise_gate()
        self.assertEqual([method for _, method, _ in writes], ["POST", "POST", "PATCH"])
        self.assertIn("`LANE_D_OUTSIDER`", writes[1][2]["body"])
        self.assertEqual(writes[2][2], {"state": "closed"})
        self.assertFalse(any("/merge" in endpoint for endpoint, _, _ in writes))

    def test_lane_c_only_labels_and_never_closes_or_merges(self):
        writes = self.exercise_gate(verdict="ROUTE")
        self.assertEqual(len(writes), 1)
        self.assertEqual(writes[0][2], {"labels": ["lane-c"]})


class WorkflowRules(unittest.TestCase):
    def test_missing_top_level_permissions_cannot_inherit_write_defaults(self):
        self.assertIn("missing top-level permissions", check_workflows.violations("jobs:\n  permissions: read-all\n"))

    def test_tagged_and_docker_actions_cannot_float(self):
        for action in ("actions/checkout@v4", "docker://example:latest", "owner/repo/.github/workflows/a.yml@main"):
            self.assertTrue(check_workflows.violations(f"permissions: {{}}\n  - uses: {action}\n"))
        self.assertEqual(check_workflows.violations("permissions: {}\n  - uses: actions/checkout@" + "a" * 40 + " # v4\n"), [])

    def test_inline_and_quoted_uses_cannot_hide_floating_actions(self):
        for text in ('steps: [{uses: actions/checkout@v4}]', "  - 'uses': 'actions/checkout@v4'", '  - uses:'):
            self.assertIn("unpinned action", "\n".join(check_workflows.violations("permissions: {}\n" + text)))

    def test_target_event_with_head_checkout_is_forbidden(self):
        source = "permissions: {}\non: [pull_request_target]\nsteps:\n  - uses: actions/checkout@" + "a" * 40 + "\n    with:\n      ref: ${{ github.event.pull_request.head.sha }}\n"
        self.assertIn("pull_request_target forbidden", "\n".join(check_workflows.violations(source)))


if __name__ == "__main__":
    unittest.main()
