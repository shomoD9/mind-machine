/* AppKit execution of portable line edit plans. MarkdownCaptureTextView calls
 this only from Enter/Tab/Backtab and Cmd-Shift-Return hooks; ordinary typing,
 arrow selection, styling and the Capture model never invoke this adapter. */
#if os(macOS)
import AppKit
import MindMachineCore

@MainActor
enum MacMarkdownEditingCommands {
    static func isTaskToggle(_ event: NSEvent) -> Bool {
        event.type == .keyDown && (event.keyCode == 36 || event.keyCode == 76)
            && event.modifierFlags.intersection([.command, .shift, .option, .control]) == [.command, .shift]
    }

    /// True consumes a recognized command, including delegate-vetoed edits and
    /// root outdent. False lets NSTextView keep its normal behavior.
    static func apply(_ command: MarkdownEditingCommands.Command, to editor: NSTextView) -> Bool {
        guard editor.isEditable, !editor.hasMarkedText(), editor.selectedRanges.count == 1,
              let storage = editor.textStorage else { return false }
        let selection = editor.selectedRange()
        guard selection.location <= storage.length else { return false }
        let source = storage.mutableString
        let lineRange = source.lineRange(for: NSRange(location: selection.location, length: 0))
        var length = lineRange.length
        if length > 0, source.character(at: NSMaxRange(lineRange) - 1) == 10 { length -= 1 }
        let localSelection = NSRange(location: selection.location - lineRange.location, length: selection.length)
        guard let plan = MarkdownEditingCommands.plan(
            line: source.substring(with: NSRange(location: lineRange.location, length: length)),
            selection: localSelection, command: command) else { return false }
        guard !plan.edits.isEmpty else { return true }
        // Each plan currently has one minimal replacement. Native change
        // approval records undo; explicit boundaries prevent adjacent typing or
        // another command from coalescing into the same Cmd-Z operation.
        editor.breakUndoCoalescing()
        let undo = editor.undoManager
        undo?.beginUndoGrouping()
        defer {
            undo?.endUndoGrouping()
            editor.breakUndoCoalescing()
        }
        for edit in plan.edits.reversed() {
            let range = NSRange(location: lineRange.location + edit.range.location, length: edit.range.length)
            guard editor.shouldChangeText(in: range, replacementString: edit.replacement) else { return true }
            storage.replaceCharacters(in: range, with: edit.replacement)
        }
        editor.setSelectedRange(NSRange(location: lineRange.location + plan.selection.location, length: plan.selection.length))
        editor.didChangeText()
        return true
    }
}
#endif
