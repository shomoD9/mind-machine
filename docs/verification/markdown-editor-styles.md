# Markdown editor ticket 2 verification

Source: `/workspace/research/markdown-editor.md`, Recommendation, Architecture, Line states, Speed gates and ticket 2. Local issue: [26](../../.scratch/native-mvp/issues/26-markdown-editor-source-preserving-styles.md).

The Linux fast lane runs `MarkdownParagraphTests`. Hosted Mac SwiftPM tests run `MacMarkdownEditorTests` against TextKit 2, native text storage/delegates, a unique pasteboard and `VaultModel` save/reopen. Exact UTF-8 byte assertions include decomposed accents, joined emoji, CRLF and trailing newlines. They also exercise prefix removal, only-the-edited-paragraph styling, newline joins, native undo/redo and composition deferral. Existing Mac Capture/Recall XCUITest and sandbox self-test remain enabled.

## Timing comparison

Before: unchanged merged-main `e4cc5d5`, fresh [native-ci run 40153281833](https://github.com/shomoD9/mind-machine/actions/runs/40153281833). After: pending first branch run. Both use ticket 1's Debug shared-Mac profile: 20 warm opens, 100 keys per 1/10/100 KiB fixture and 100 KiB huge paragraph, plus a 1 MiB insertion. Raw samples remain in each run's `pill-selftest/result.json` artifact under `captureBaseline`.

The unchanged baseline already misses the proposed 33 ms huge-paragraph p95 on shared CI. Draw completion remains a proxy for visible glyph latency. Paragraph styling is measured separately after this change; it does not measure all custom application work. Release M1 Air/macOS 14, cold launches, compositor latency and physical input require the [manual hardware procedure](markdown-editor-baseline.md). No hardware numbers are inferred from CI.

## Scope review

Mac source handling and new parser/styler files own this change. The SwiftUI editor layout/format controls, PillPanelView/PillRootView, iPhone/keyboard behavior, PRODUCT, workflows, signing/entitlements and release pipeline are untouched. `RichNoteEditor.swift` has small Mac adapter edits because both this ticket and PR #10 use that seam; its view body and layout styling are unchanged. Markers retain their advance, and no continuation/formatting commands or fence-context pipeline were added.
