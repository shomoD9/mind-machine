/* Computes Capture's post-edit presentation boundary without owning source or
 AppKit state. MacMarkdownEditor uses this direct UTF-16 accessor seam; portable
 oracle tests compare the result with independent whole-document parsing. */
import Foundation

public enum MarkdownContextInvalidation {
    /// The recognised Capture subset has no dependencies between intact lines.
    /// Include the edit's right endpoint: a newly inserted separator can leave
    /// old attributes on the new right paragraph even though it contains none of
    /// the inserted characters. Ordinary edits still visit only their paragraph.
    public static func affected(by edit: NSRange, length: Int,
                                characterAt: (Int) -> UInt16) -> NSRange? {
        let location = min(edit.location, length)
        let count = min(edit.length, length - location)
        let inclusiveCount = count + (location + count < length ? 1 : 0)
        return MarkdownStyleRange.affected(by: NSRange(location: location, length: inclusiveCount),
                                          length: length, characterAt: characterAt)
    }
}
