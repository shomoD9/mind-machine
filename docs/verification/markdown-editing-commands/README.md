# Markdown editing commands

Ticket 28 implements research ticket 4. Source remains literal Markdown. Cmd-Shift-Return toggles tasks; Cmd-Return remains Save. Checkbox clicks and quote continuation are outside this change.

## Before

At main `61eca6a`, `MarkdownCaptureTextView` overrides only paste. Source inspection confirms every editing key uses stock AppKit behavior; no live Mac observation was possible on this Linux host.

| Key and source | Main behavior | New behavior |
| --- | --- | --- |
| Enter after `- item` / `* item` | Bare newline | Same bullet on the new line |
| Enter after `- [x] task` / `- [ ] task` | Bare newline | Fresh `- [ ] ` on the new line |
| Enter after marker-only `- ` / task / `1. ` | Newline retains old marker | Remove marker, keep indent, stay on line |
| Enter after `1. item` | Bare newline | `2. ` on the new line |
| Tab on a list/task | Native tab action; no Markdown indent edit | Add two leading spaces |
| Shift-Tab on a list/task | Native backtab action; no Markdown outdent edit | Remove up to two leading spaces |
| Cmd-Shift-Return on a task | No task-toggle command | Flip only the check character |

The first executable portable probe failed with `XCTUnwrap failed: expected non-nil value of type "Plan"` for bullet continuation. After adding that behavior, the remaining tests failed with 20 assertions, including an unchecked task continuation returning only a bullet (`32 bytes` versus expected `36 bytes` in the Unicode fixture). Those tests pass with the final planner.

## Local after evidence

Swift 6.2.1, Linux:

```sh
/tmp/mm-swift/swift-6.2.1-RELEASE-ubuntu24.04/usr/bin/swift test --package-path native --jobs 2
```

39 tests pass, zero failures, including these nine `MarkdownEditingCommandsTests`:

- `testEnterContinuesBulletAtSameNestedIndent`
- `testEnterContinuesTasksUnchecked`
- `testEnterExitsEmptyItemsKeepingIndent`
- `testEnterIncrementsNumberedListsAndKeepsNestedIndent`
- `testEnterSplitsBodyAndReplacesSelection`
- `testTabAndBacktabMoveOnlyIndentAndPreserveSelection`
- `testToggleChangesOneMarkerCharacterAndKeepsSelection`
- `testUnicodeBytesAndUTF16CaretsSurviveEveryCommand`
- `testPlainCodeMalformedAndMultilineInputsUseNativeFallback`

Exact UTF-8 comparisons cover emoji, combining marks and untouched text; UTF-16 selection assertions cover insertion, replacement, indentation and toggling. Newlines inserted by the planner are LF. The touched Mac Swift files pass syntax parsing locally; Linux cannot compile or execute AppKit.

## Hosted and manual Mac evidence

First hosted round at `3ac2cb3`: [core-checks 40199148582](https://github.com/shomoD9/mind-machine/actions/runs/40199148582) passed every gate. The main package ran 63 tests (one pre-existing skip), including all nine portable command tests and all nine Mac editor tests. The separate Pill package passed 35 tests. Native undo/redo and composition checks below passed on actual AppKit.

[native-ci 40199148608](https://github.com/shomoD9/mind-machine/actions/runs/40199148608) passed the Mac app/sandbox self-test, Mac UI acceptance, keyboard UI acceptance and iOS build/screenshots. Its Swift job stopped before the editor tests in unchanged `SearchPerformanceTests.testTenThousandNotesQueryBudget`: durable-append p95 16.033708 ms versus 12 ms. The separate passing core-checks process benchmark measured append p95 4.510 ms. No threshold or deadline changed.

The sandbox artifact reports no failed checks and TextKit 2 throughout. Draw-proxy p95 was 3.481 / 3.657 / 5.382 ms for 1/10/100 KiB, and 53.465 ms for one 100 KiB paragraph. The huge-paragraph fixture still exceeds the proposed 33 ms budget (main's PR #14 evidence reports 72.679 ms); shared-runner variation prevents a speedup claim. Physical key-to-pixel and M1 Air measurements remain unverified.

A second hosted checkpoint removes the redundant `keyDown` fallback and tests the task shortcut through the containing window; its results will be recorded in the PR. `MacMarkdownEditorTests.testEditingCommandsAreSingleUndoStepsAndPreserveSurroundingSource` drives each override and the real Cmd-Shift-Return key equivalent, checks exact source with a preceding line, then verifies one undo and one redo. `testCommandSelectionCompositionAndPlainFallbackStayNative` drives arrow selection, Tab, a plain newline and marked-input shortcut fallback. Existing typing/timing tests and budgets remain unchanged; no physical key-to-pixel or M1 Air measurement is claimed.

For a manual before/after capture, open main and this branch on a Mac with a disposable draft. Type `- item`, Enter, Enter; repeat with `- [x] task` and `9. item`. On this branch confirm continuation then marker exit. On a task with emoji and a decomposed accent, press Tab, Shift-Tab and Cmd-Shift-Return, undoing each once. Select body text with Shift-arrows and repeat Tab; compose Japanese text and confirm command keys remain native until commit. Record the draft text and selection before/after, and use screen recording for visual evidence. No recording has been captured on this Linux host.
