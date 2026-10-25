# Markdown context invalidation — ticket 30

Inserting a newline must restyle both resulting paragraphs. The previous invalidator used only the inserted characters, so a separator at the end of an edit excluded the right paragraph. `MarkdownContextInvalidation.affected` includes the edit's right endpoint before invoking the existing bounded discovery. Mac Capture records character edits in `willProcessEditing`, before native attribute fixing can widen their range through an existing newline, then calls that pure core function against text storage from `textDidChange`. Ordinary character edits still return only their containing paragraph.

## Before and after

Baseline: `origin/main` at `63ec2e8f1773123020a76fb3b3ae812164f507c1`.

| Edit | Baseline incremental presentation | Full parsing / after |
| --- | --- | --- |
| Insert LF at UTF-16 offset 4 in `**bold**` | Restyles `{0,5}`; `ld` retains bold and the last `**` retain marker ink | Restyles `{0,9}`; both incomplete lines are plain |
| Split `[**label**](url)` within its label | Right fragment can retain link/marker attributes | Both fragments are reclassified |
| Join `**bo` + LF + `ld**` | Already agrees with full parsing | Still agrees; joined word is bold |
| Add/remove leading spaces or tab on a list/task | Already agrees with full parsing | Still agrees with the current line-local prefix/code rules |

The first committed regression (`743a380`) runs against the original range function: two tests, two assertion failures in the split test (`{0,5}` versus `{0,9}` and stale effective style units). Running the final nine-test portable suite with only its oracle helper switched back to `MarkdownStyleRange` produces **464 assertion failures**. These include subsequent stale-state observations, not 464 distinct defects. The same suite with `MarkdownContextInvalidation` passes.

Portable evidence: **39 tests pass**, including **9 context tests**. `testSeededRandomEditSequencesMatchFullParseAndExactSourceBytes` executes **4,800 edits** (12 fixed seeds × 400) and compares effective block/inline styling with independent Foundation whole-source paragraph discovery after every edit. `testEverySplitAndJoinAcrossRecognisedSyntaxAndUnicode` adds **848 edits**, exhaustively splitting/joining six fixtures at Unicode scalar boundaries with LF, CR, CRLF and U+2029. Tests also cover multi-line replacements, full deletion, document edges, list/task indentation, current fence/reference-looking literal input, locality and the cap. Byte assertions use independently spliced UTF-8, including emoji, ZWJ sequences, composed/decomposed accents and edits to combining marks. The source mutation model uses exact UTF-16 replacement because Linux Foundation's String replacement rounds some scalar boundaries to grapheme boundaries.

`MacMarkdownEditorTests.testContextEditsMatchFreshWholeDocumentAttributes` compares actual AppKit attributes at every UTF-16 unit after 12 native edits with a fresh full-source restoration, and checks exact source bytes and TextKit 2. It uses no sleeps, UI timing or pasteboard. Existing native undo/composition tests remain unchanged.

Run locally:

```sh
/tmp/mm-swift/swift-6.2.1-RELEASE-ubuntu24.04/usr/bin/swift test --package-path native
# On macOS (also run by existing hosted SwiftPM jobs):
swift test --package-path native --filter MacMarkdownEditorTests
```

## Context and bounded work

The existing `MarkdownParagraph` subset recognises headings, bullets/tasks, asterisk emphasis and inline links independently on each physical paragraph. Leading code indentation and fence-start lines stay plain. Fenced-block continuation, reference-style definitions/resolution, Setext headings, nested lists, and inherited container indentation are not recognised. Fence state would introduce unbounded forward propagation; reference resolution would require a document symbol table and dependent-link invalidation. Implementing these together with bounded scheduling exceeds this correction to the existing parser, so this ticket retains and tests its actual subset. This is not a CommonMark-completeness claim.

No parser or presentation job runs asynchronously. Parsing and attribute application complete within the native text-change callback; stale asynchronous overwrite is impossible by construction. Marked text retains the existing deferred styling path.

The existing **8,192 UTF-16 affected-span cap** is unchanged, including the combined span for a split. Discovery rejects oversized work before copying, parsing or attribute enumeration. Virtual 1 GB paragraph probes read at most 8,194 units; bulk input over the cap performs zero reads. An edit in a 170 KB multi-paragraph fixture reads only its paragraph and its boundary separator. The full-parse equality oracle exercises bounded styling; oversized spans retain the existing native-attribute fallback (including inherited attributes), and do not promise a forced whole-document restyle. Large bulk restorations remain native source until bounded edits occur.

## Hosted checks and timing

First push `2171e99`: both Linux fast-core checks, both app builds, both UI acceptance jobs and the sandbox self-test passed. [native-ci 40199412113](https://github.com/shomoD9/mind-machine/actions/runs/40199412113) and [core-checks 40199412166](https://github.com/shomoD9/mind-machine/actions/runs/40199412166) both caught the same existing locality assertion: `{8,13}` versus `{8,7}` in `testOnlyEditedParagraphChangesAndNewlineDoesNotInheritHeading`. The new portable and actual-AppKit oracles passed. The callback used `didProcessEditing`; native attribute repair had widened an ordinary edit through the trailing separator, so endpoint inclusion then reached the next paragraph. The second push records the edit at `willProcessEditing` and still applies attributes only in `textDidChange`. This follows Apple's [before-attribute-fixing callback contract](https://developer.apple.com/documentation/appkit/nstextstoragedelegate/textstorage(_:willprocessediting:range:changeinlength:)). Existing locality/undo/composition/huge-paragraph assertions are unchanged. The second push `ade796b` passed all eight hosted checks: [native-ci 40203413521](https://github.com/shomoD9/mind-machine/actions/runs/40203413521), [core-checks 40203413517](https://github.com/shomoD9/mind-machine/actions/runs/40203413517), [fast-core push 40203410263](https://github.com/shomoD9/mind-machine/actions/runs/40203410263) and [fast-core PR 40203413564](https://github.com/shomoD9/mind-machine/actions/runs/40203413564). All existing tests, deadlines, repetition counts and timing budgets are retained. The unchanged-main native run is [40194786090](https://github.com/shomoD9/mind-machine/actions/runs/40194786090). Its raw `captureBaseline` artifact is the before measurement. Shared-runner draw completion remains a proxy; physical M1 Air/macOS 14 typing p95 ≤33 ms cannot be established on Linux. Main's existing 100 KiB single-paragraph result is already over that budget; see [capture speed evidence](../capture-speed/README.md).

## Mac behaviour capture

On a Mac, use Capture on main and this branch with the same appearance and note font. Type `**bold**`, place the caret between `o` and `l`, and press Return. Before: `ld` can stay bold and its closing markers muted. After: both incomplete lines are plain. Backspace at the start of `ld**` restores a single bold word. Repeat with a heading containing emphasis, a linked label, and a task; add/remove leading spaces and a tab. Record the writing area before/after each edit and retain the exact copied source. No toolbar or new control is involved. The deterministic AppKit test performs the attribute equivalent; no local macOS screenshot is claimed.

## Integration with ticket 4

Merged `origin/main` at `278a905` (PR #16) into `ade796b`. Retained all portable context and command tests plus the AppKit attribute oracle, command undo/redo and composition tests. The production editor combines command hooks with `willProcessEditing` and `MarkdownContextInvalidation`; command source edits use that same invalidation path. Integration Linux verification passes: all 48 Swift tests (including nine context and nine command tests) and all 17 Python watchdog tests. All ten merged AppKit test bodies are the exact union of both parents; other test files are byte-for-byte identical to their respective parents. Touched Mac sources parse and whitespace checks pass. Hosted verification of the integration commit is pending; results will be appended to `/tmp/mm-mdctx-result.md`.

## Integration with Recall cards

Merged `origin/main` at `12f53bd` (PR #15) into `e1b48ec`. Both implementations and their tests are retained unchanged; only the journal required manual conflict resolution. Recall keeps tracker number 29; context invalidation moves to [ticket 30](../../../.scratch/native-mvp/issues/30-markdown-editor-context-invalidation.md). Linux and hosted integration verification is recorded in `/tmp/mm-mdctx-result.md`.
