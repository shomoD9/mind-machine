# Day in the life and rough interface

Map: [Scattered ambitious pitch](../map.md)
Type: prototype
Label: wayfinder:prototype
Status: claimed
Blocked by: none

## Question

Given [What capture must preserve](10-what-capture-must-preserve.md) and [Form of the creation session](11-form-of-the-creation-session.md), what does a day look like for the maker, and what is the rough interface we react to?

The prototype is cheap and concrete: a day, and an interface rough enough to argue with. Production visual design is out of scope. The human reacts. The agent does not treat silence as approval.

## Comments

### 2026-09-30 — Sonnet 5.5 — Claude Code Desktop

Built a throwaway prototype: [prototypes/07-day-and-rough-interface/index.html](../prototypes/07-day-and-rough-interface/index.html). Open the file by double-click. No install, nothing stored.

It walks one day through four apps the maker already has open: an X post at 08:50, a newsletter draft at 11:30, a chat with Priya at 14:15, and a script at 17:40. In the draft, capture opens as a blurred overlay with adjacent dialogs, a wikilink to an independent note, a split hint whose acceptance is Explode, and optional related notes. Typing in any app surfaces earlier notes, and one click puts the note into the box.

Three structurally different versions of the point-of-decision surface, switched with the bottom bar or `?variant=`: A, a card that follows the text cursor; B, notes in a margin column at the window edge; C, a strip of suggestions under the text box. The right panel shows the dump, the count of acts, and why each note appeared.

Assumptions the human has not settled, listed on the prototype's page: the click inserts the note into the box, surfacing needs 4 typed words and 2 shared words, key combinations are placeholders, the split hint cuts at lines or sentences, and related notes in capture are not clickable. Checked in the browser pane: the three versions render, the click inserts, and the split hint, wikilink, and close all work. Nothing awaits the human's verdict yet, and the ticket stays claimed until they react.
