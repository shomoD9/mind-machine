-------------------------- MODULE MindMachineSync --------------------------
(***************************************************************************)
(* What this file is: a TLA+ model of how Mind Machine keeps notes safe     *)
(* when two writers share one phone vault (app + keyboard) and a Mac vault, *)
(* all syncing through one CloudKit zone. TLC (spec/run-tlc.sh) tries every *)
(* order of the steps below up to a small bound.                            *)
(*                                                                          *)
(* Who reads it: spec/run-tlc.sh and the *.cfg files beside it,             *)
(* .agents/skills/verify-mindmachine-sync/SKILL.md, docs/state-machines/    *)
(* software.md and the bug tickets in .scratch/state-machines/issues/.      *)
(*                                                                          *)
(* Historical switches model c45031b; fixed configs model overnight-core. *)
(* Paths are under           *)
(* native/Sources/MindMachineCore/:                                         *)
(*   VaultFile.swift   SQLite vault: append, update, merge, materialize     *)
(*   PrivateCloudSync.swift  CKSyncEngine adapter: upload, ack, fetch       *)
(*   NoteRevision.swift  immutable revision {id, noteID, capture?, parents} *)
(* Not modelled: encryption, account changes, Paused state, the 100-row     *)
(* batch limit, SQLite busy errors, search ranking, reminders and chat      *)
(* (those stay on one device and never sync).                               *)
(*                                                                          *)
(* Modelling choices, each one a claim about the code:                      *)
(*  - A SQLite write transaction is one atomic step (BEGIN IMMEDIATE,       *)
(*    VaultFile.swift:354). App and keyboard therefore share one store.     *)
(*  - A revision is a number. Its parents, note and content never change.   *)
(*  - A tombstone is a revision whose capture is nil (VaultFile.swift:136). *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
    MaxRev,                 \* most revisions that will ever exist (search bound)
    MaxRoots,               \* most distinct notes that will ever be captured
    MaxCrash,               \* most process crashes in one run (crashes cannot repeat forever)
    Values,                 \* content tokens, e.g. a checklist ticked or not
    TombstoneRule,          \* "Dominates" = shipped code; "Ancestry" = proposed fix
    CollapseIdentical,      \* FALSE = shipped code; TRUE = proposed fix
    UploadParentsFirst,     \* causal-cloud assumption; current code handles arbitrary arrival
    RequireCompleteAncestry, \* TRUE = current receive-side staging of incomplete revisions
    FaultAckEarly           \* TRUE = deliberately broken upload, proves checks can fail

Dev  == {"phone", "mac"}
Proc == {"app", "kbd", "mac"}          \* processes that run a sync engine
DevOf == [p \in Proc |-> IF p = "mac" THEN "mac" ELSE "phone"]

VARIABLES
    info,       \* info[r] = [kind, parents, note, val, covers]; fixed once r exists
    nextId,     \* next revision number to create
    store,      \* store[d]  = revisions in device d's SQLite `revisions` table
    outbox,     \* outbox[d] = rows with pending=1 (shared by app and keyboard)
    log,        \* the cloud zone's change log, in arrival order, no repeats
    engPend,    \* engPend[p] = CKSyncEngine pending saves in process p's state
    cursor,     \* cursor[p]  = how much of `log` process p has fetched
    gone,       \* ghost: revisions a person explicitly chose to delete
    crashes     \* how many crashes have happened

vars == <<info, nextId, store, outbox, log, engPend, cursor, gone, crashes>>

Created == 1 .. (nextId - 1)
IsPut(r)    == info[r].kind = "put"
NoteOf(r)   == info[r].note
Parents(r)  == info[r].parents

(***************************************************************************)
(* What a device shows in Recall for one note, as a function of the         *)
(* revisions it holds. This is VaultFile.materialize (VaultFile.swift:336)  *)
(* and heads (VaultFile.swift:322).                                         *)
(***************************************************************************)
Revs(S, n) == {r \in S : NoteOf(r) = n}
Tombs(S, n) == {r \in Revs(S, n) : ~IsPut(r)}
\* A content head is a content revision that no other content revision lists as parent.
RECURSIVE AncGlobal(_)
\* Every true ancestor of r, from the permanent revision graph (not what a device holds).
AncGlobal(r) == {r} \cup UNION {AncGlobal(q) : q \in Parents(r)}


\* VaultFile.materialize only projects revisions with their complete parent chain.
Projectable(S) == IF RequireCompleteAncestry THEN {r \in S : AncGlobal(r) \subseteq S} ELSE S

ContentHeads(R) == {r \in R : IsPut(r) /\ ~\E s \in R : IsPut(s) /\ r \in Parents(s)}
Covers(S, n) == UNION {info[t].covers : t \in Tombs(Projectable(S), n)}

Collapse(H) ==
    IF CollapseIdentical
    THEN {h \in H : ~\E g \in H : info[g].val = info[h].val /\ g < h}
    ELSE H

Visible(S, n) ==
    LET heads == ContentHeads(Revs(Projectable(S), n))
    IN IF TombstoneRule = "Dominates"
       \* VaultFile.swift:345: any tombstone for the note hides every branch.
       THEN IF Tombs(S, n) # {} THEN {} ELSE Collapse(heads)
       \* Proposed: a tombstone hides only what it names.
       ELSE Collapse({h \in heads : h \notin Covers(S, n)})

\* VaultFile's projectionRevisions remembers all equivalent live heads.
CopyHeads(S, n, x) ==
    IF CollapseIdentical
    THEN {h \in ContentHeads(Revs(Projectable(S), n)) \ Covers(S, n) : info[h].val = info[x].val}
    ELSE {x}

Notes(S) == {NoteOf(r) : r \in S}
VisibleAll(d) == UNION {{<<n, info[h].val>> : h \in Visible(store[d], n)} : n \in Notes(store[d])}


RECURSIVE AncLocal(_, _)
\* The revision and every ancestor the device can see from its own table.
AncLocal(S, r) ==
    {r} \cup UNION {IF p \in S THEN AncLocal(S, p) ELSE {p} : p \in Parents(r)}

Init ==
    /\ info = <<>>
    /\ nextId = 1
    /\ store = [d \in Dev |-> {}]
    /\ outbox = [d \in Dev |-> {}]
    /\ log = <<>>
    /\ engPend = [p \in Proc |-> {}]
    /\ cursor = [p \in Proc |-> 0]
    /\ gone = {}
    /\ crashes = 0

(***************************************************************************)
(* Person actions. Each is one SQLite transaction in one process.           *)
(***************************************************************************)

\* VaultFile.append (VaultFile.swift:147): a new note, revision with no parents,
\* queued with pending=1 in the same transaction as the original.
Capture(p, v) ==
    LET d == DevOf[p] IN
    /\ nextId <= MaxRev
    /\ Cardinality({r \in Created : info[r].parents = {}}) < MaxRoots
    /\ info' = info @@ (nextId :> [kind |-> "put", parents |-> {}, note |-> nextId,
                                   val |-> v, covers |-> {}])
    /\ store' = [store EXCEPT ![d] = @ \cup {nextId}]
    /\ outbox' = [outbox EXCEPT ![d] = @ \cup {nextId}]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<log, engPend, cursor, gone, crashes>>

\* VaultFile.update (VaultFile.swift:120) for a changed capture, e.g. a ticked
\* checklist item. The new revision's parent is the revision behind the visible
\* copy that was edited (identity, VaultFile.swift:329). An unchanged value
\* makes no revision (VaultFile.swift:128).
Edit(p, n, h, v) ==
    LET d == DevOf[p] IN
    /\ nextId <= MaxRev
    /\ h \in Visible(store[d], n)
    /\ v # info[h].val
    /\ info' = info @@ (nextId :> [kind |-> "put", parents |-> CopyHeads(store[d], n, h), note |-> n,
                                   val |-> v, covers |-> {}])
    /\ store' = [store EXCEPT ![d] = @ \cup {nextId}]
    /\ outbox' = [outbox EXCEPT ![d] = @ \cup {nextId}]
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<log, engPend, cursor, gone, crashes>>

\* VaultFile.update for a removed capture (VaultFile.swift:134-138). The shipped
\* tombstone lists every head of the note as parents, even when the person
\* removed only one displayed copy x. No screen offers delete today, so this
\* models the code path the tests exercise (ReplicationTests.swift:31).
Delete(p, n, x) ==
    LET d == DevOf[p]
        heads == ContentHeads(Revs(store[d], n))
    IN
    /\ nextId <= MaxRev
    /\ x \in Visible(store[d], n)
    /\ info' = info @@ (nextId :> [kind |-> "del",
                          parents |-> IF TombstoneRule = "Dominates" THEN heads ELSE CopyHeads(store[d], n, x),
                          note |-> n, val |-> info[x].val,
                          covers |-> UNION {AncLocal(store[d], h) : h \in CopyHeads(store[d], n, x)}])
    /\ store' = [store EXCEPT ![d] = @ \cup {nextId}]
    /\ outbox' = [outbox EXCEPT ![d] = @ \cup {nextId}]
    /\ gone' = gone \cup {x}
    /\ nextId' = nextId + 1
    /\ UNCHANGED <<log, engPend, cursor, crashes>>

(***************************************************************************)
(* Sync actions, one process at a time.                                     *)
(***************************************************************************)

\* PrivateCloudSync.synchronize (PrivateCloudSync.swift:47-51): the process adds
\* every pending revision to its engine state.
Register(p) ==
    /\ outbox[DevOf[p]] \ engPend[p] # {}
    /\ engPend' = [engPend EXCEPT ![p] = @ \cup outbox[DevOf[p]]]
    /\ UNCHANGED <<info, nextId, store, outbox, log, cursor, gone, crashes>>

\* nextRecordZoneChangeBatch + CloudKit save (PrivateCloudSync.swift:119-133).
\* Only revisions that are still pending in the shared table are sent. A record
\* that already exists on the server is the serverRecordChanged case, which the
\* code treats as saved (PrivateCloudSync.swift:92-101).
Save(p, r) ==
    /\ r \in engPend[p] \cap outbox[DevOf[p]]
    /\ r \notin {log[i] : i \in 1 .. Len(log)}
    \* Shipped code sends newest first (VaultFile.swift:301, ORDER BY rowid DESC).
    /\ UploadParentsFirst => Parents(r) \subseteq {log[i] : i \in 1 .. Len(log)}
    /\ log' = Append(log, r)
    /\ UNCHANGED <<info, nextId, store, outbox, engPend, cursor, gone, crashes>>

\* sentRecordZoneChanges: acknowledge sets pending=0 (VaultFile.swift:303).
\* This is a separate step from Save, so a crash between them is covered.
Ack(p, r) ==
    /\ r \in engPend[p] \cap outbox[DevOf[p]]
    /\ FaultAckEarly \/ r \in {log[i] : i \in 1 .. Len(log)}
    /\ outbox' = [outbox EXCEPT ![DevOf[p]] = @ \ {r}]
    /\ engPend' = [engPend EXCEPT ![p] = @ \ {r}]
    /\ UNCHANGED <<info, nextId, store, log, cursor, gone, crashes>>

\* fetchedRecordZoneChanges then store.merge (PrivateCloudSync.swift:75-83,
\* VaultFile.swift:306). INSERT OR IGNORE keeps an existing row, including its
\* pending flag. The cursor moves with the merge: the code persists the new
\* cursor only after a successful merge.
Fetch(p) ==
    LET d == DevOf[p]
        r == log[cursor[p] + 1]
    IN
    /\ cursor[p] < Len(log)
    /\ store' = [store EXCEPT ![d] = @ \cup {r}]
    /\ cursor' = [cursor EXCEPT ![p] = @ + 1]
    /\ UNCHANGED <<info, nextId, outbox, log, engPend, gone, crashes>>

\* A process dies. Its in-memory engine list is gone; the table is durable.
Crash(p) ==
    /\ crashes < MaxCrash
    /\ engPend[p] # {}
    /\ engPend' = [engPend EXCEPT ![p] = {}]
    /\ crashes' = crashes + 1
    /\ UNCHANGED <<info, nextId, store, outbox, log, cursor, gone>>

Next ==
    \/ \E p \in Proc, v \in Values : Capture(p, v)
    \/ \E p \in Proc, n \in Created, h \in Created, v \in Values : Edit(p, n, h, v)
    \/ \E p \in Proc, n \in Created, x \in Created : Delete(p, n, x)
    \/ \E p \in Proc : Register(p) \/ Fetch(p) \/ Crash(p)
    \/ \E p \in Proc, r \in Created : Save(p, r) \/ Ack(p, r)

\* Every process keeps running its sync loop (the app, keyboard and Mac each
\* run synchronize on activation, after commits, and every 15 s).
Fairness ==
    /\ \A p \in Proc : WF_vars(Register(p)) /\ WF_vars(Fetch(p))
    /\ \A p \in Proc, r \in 1 .. MaxRev : WF_vars(Save(p, r)) /\ WF_vars(Ack(p, r))

Spec == Init /\ [][Next]_vars /\ Fairness

(***************************************************************************)
(* Projection safety needs four revisions (base, two edits, delete), but    *)
(* not every engine cursor/outbox interleaving. DeliverRevision abstracts   *)
(* cloud save+fetch as delivery of ANY created revision, including before   *)
(* parents. This overapproximates transport for safety; liveness remains    *)
(* covered by Spec, not this abstraction. Swift SyncInvariantTests replay   *)
(* both these projection stories and the 100-record transport boundary.     *)
(***************************************************************************)
DeliverRevision(d, r) ==
    /\ r \in Created \ store[d]
    /\ store' = [store EXCEPT ![d] = @ \cup {r}]
    /\ UNCHANGED <<info, nextId, outbox, log, engPend, cursor, gone, crashes>>

ProjectionNext ==
    \/ \E p \in Proc, v \in Values : Capture(p, v)
    \/ \E p \in Proc, n \in Created, h \in Created, v \in Values : Edit(p, n, h, v)
    \/ \E p \in Proc, n \in Created, x \in Created : Delete(p, n, x)
    \/ \E d \in Dev, r \in Created : DeliverRevision(d, r)

ProjectionSpec == Init /\ [][ProjectionNext]_vars

(***************************************************************************)
(* Rules. Each has one plain sentence; spec/run-tlc.sh checks them one by   *)
(* one so each failure is reported on its own.                              *)
(***************************************************************************)

TypeOK ==
    /\ nextId \in 1 .. (MaxRev + 1)
    /\ \A d \in Dev : store[d] \subseteq Created /\ outbox[d] \subseteq store[d]
    /\ Len(log) <= MaxRev
    /\ \A p \in Proc : cursor[p] <= Len(log)
    /\ crashes <= MaxCrash

\* A content head that is neither shown nor named by a tombstone's covers set
\* has been dropped without the person choosing to drop it.
LostHeads(d) ==
    {c \in ContentHeads(Projectable(store[d])) :
        /\ c \notin Visible(store[d], NoteOf(c))
        /\ c \notin Covers(store[d], NoteOf(c))
        \* A copy folded into an identical visible copy is not lost.
        /\ ~(CollapseIdentical /\ \E v \in Visible(store[d], NoteOf(c)) : info[v].val = info[c].val)}

\* RULE 1. "No captured note is ever lost": a note that still has a head the
\* person never deleted does not vanish from Recall.
NoCapturedNoteLost ==
    \A d \in Dev : \A n \in Notes(store[d]) :
        (ContentHeads(Revs(Projectable(store[d]), n)) \ Covers(store[d], n) # {})
            => Visible(store[d], n) # {}

\* RULE 1a. Deleting one displayed copy of a conflicted note keeps the other copy.
DeleteSparesOtherCopies ==
    \A d \in Dev : \A c \in LostHeads(d) :
        ~\E t \in store[d] : ~IsPut(t) /\ c \in Parents(t)

\* RULE 1b. A delete does not discard an edit the person who deleted never saw.
DeleteSparesUnseenEdits ==
    \A d \in Dev : \A c \in LostHeads(d) :
        \E t \in store[d] : ~IsPut(t) /\ c \in Parents(t)

\* RULE 3. "No duplicate notes after merge": two copies of one note shown in
\* Recall never carry identical content.
NoDuplicateCopies ==
    \A d \in Dev : \A n \in Notes(store[d]) :
        \A a, b \in Visible(store[d], n) : a # b => info[a].val # info[b].val

\* RULE 4. Recall never shows an older version of a note beside its newer version.
\* Breaks when a revision arrives before its parent: the parent's own parent (or the
\* parent's sibling) has no newer revision to hide behind yet.
NoStaleCopyBesideNewer ==
    \A d \in Dev : \A n \in Notes(store[d]) :
        \A a, b \in Visible(store[d], n) : a # b => a \notin AncGlobal(b)

\* Restricts a run to deliveries where every revision's parents are already present.
\* Used only to find the next counterexample once the out-of-order one is known.
CausalOnly == \A d \in Dev : \A r \in store[d] : Parents(r) \subseteq store[d]

\* The same rules, read only on runs where every revision arrives after its parents.
\* Used to show the next counterexample once the out-of-order one is known.
CausalNoDuplicateCopies == CausalOnly => NoDuplicateCopies
CausalDeleteSparesOtherCopies == CausalOnly => DeleteSparesOtherCopies

\* A deleted copy never comes back once the device can apply its tombstone.
\* An incomplete remote tombstone is durable transport state, not an applied
\* delete: VaultFile.materialize waits for its parents, exactly as for puts.
\* Local deletes always have complete ancestry (ReplicationTests.swift).
DeletedStaysDeleted ==
    \A d \in Dev : \A t \in Projectable(store[d]) : ~IsPut(t) =>
        info[t].covers \cap Visible(store[d], NoteOf(t)) = {}

\* RULE 2. "A note seen in Recall is eventually consistent on both devices."
\* Once nobody writes any more, both devices end up showing the same notes.
Convergence ==
    <>[](VisibleAll("phone") = VisibleAll("mac") /\ store["phone"] = store["mac"])

\* Every revision either device holds reaches the other device.
SeenReachesOther ==
    \A r \in 1 .. MaxRev :
        /\ (r \in store["phone"]) ~> (r \in store["mac"])
        /\ (r \in store["mac"]) ~> (r \in store["phone"])

=============================================================================
