# 11: Recall hits carry parsed match spans

Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Recall previews highlight the same words in the Mac/companion list and the keyboard list, from one parser.

Today the store emits text with match delimiters, the SwiftUI preview and the UIKit preview each re-parse it, and the broad-query path builds delimiters a third way.

- [ ] A hit exposes ordered spans (text, matched) and a test covers delimiter characters in the original text
- [ ] Both previews only style spans; the two delimiter parsers are deleted
- [ ] Previews look the same as before
