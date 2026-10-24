/* Durable SQLite source/index shared by the companion, keyboard and Mac through
 VaultModel. The legacy JSON URL remains the migration source and is never removed.
 Every acknowledged write commits originals, FTS and replication revisions together.
 Called by VaultModel (reads, saves, Recall), DeviceReminders (reminder-source snapshots),
 PrivateCloudSync (outbox, merge, cursor state), VaultIntegrityProbe and the Core tests. */
import Foundation
import CSQLite

public struct SearchHit: Equatable, Sendable {
    public let capture: Capture
    /// Plain text with ⟦/⟧ match delimiters, never HTML. Original stays separate.
    public let highlightedText: String
}

public final class VaultFile: @unchecked Sendable {
    public let url: URL
    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    public init(url: URL) { self.url = url }
    deinit { sqlite3_close(db) }

    private func withStore<T>(_ work: () throws -> T) throws -> T {
        lock.lock(); defer { lock.unlock() }
        if db == nil { try open() }
        return try work()
    }

    // WAL supports readers in other processes. FULL + fullfsync commits before
    // Saved; a bounded 512 KiB page cache avoids an in-memory keyboard-sized index.
    private func open() throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let path = url.deletingPathExtension().appendingPathExtension("sqlite").path
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else { throw failure() }
        do {
            sqlite3_busy_timeout(db, 5000)
            try execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA fullfsync=ON; PRAGMA cache_size=-512; PRAGMA secure_delete=ON;")
            try execute("""
                CREATE TABLE IF NOT EXISTS metadata(key TEXT PRIMARY KEY, value BLOB NOT NULL);
                CREATE TABLE IF NOT EXISTS captures(id TEXT PRIMARY KEY, payload BLOB NOT NULL, created REAL NOT NULL);
                CREATE INDEX IF NOT EXISTS captures_created ON captures(created DESC,id);
                CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(id UNINDEXED, text, tokenize='unicode61 remove_diacritics 2', prefix='2 3 4');
                CREATE VIRTUAL TABLE IF NOT EXISTS vocabulary USING fts5vocab(notes, 'row');
                CREATE TABLE IF NOT EXISTS revisions(id TEXT PRIMARY KEY, note TEXT NOT NULL, payload BLOB NOT NULL, pending INTEGER NOT NULL);
                CREATE INDEX IF NOT EXISTS revisions_note ON revisions(note);
                CREATE TABLE IF NOT EXISTS projections(id TEXT PRIMARY KEY, note TEXT NOT NULL, revision TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS projectionRevisions(id TEXT NOT NULL, revision TEXT NOT NULL, PRIMARY KEY(id,revision));
                CREATE TABLE IF NOT EXISTS spellings(term TEXT NOT NULL, word TEXT NOT NULL, PRIMARY KEY(term,word));
                """)
            try transaction {
                if try value("initialized") == nil {
                    // Decode fully before changing storage. A failed migration is
                    // rolled back, so retry never mistakes a damaged source for empty.
                    let legacy = FileManager.default.fileExists(atPath: url.path)
                        ? try JSONDecoder().decode(Vault.self, from: Data(contentsOf: url)) : Vault()
                    var metadata = legacy; metadata.captures = []
                    try put("vault", JSONEncoder().encode(metadata))
                    for capture in legacy.captures {
                        try write(capture)
                        try queue(NoteRevision(capture: capture, parents: []))
                    }
                    try put("initialized", Data([1]))
                }
                // Upgrade the first SQLite pilot without changing its sources.
                if try value("projections.branch-copies.v2") == nil {
                    var notes: [UUID] = []
                    try rows("SELECT DISTINCT note FROM revisions") { if let id = UUID(uuidString: column($0,0)) { notes.append(id) } }
                    for note in notes { try materialize(note) }
                    try put("projections.branch-copies.v2", Data([1]))
                }
                if try value("fts.rowids.aligned") == nil {
                    // Share source row IDs so broad matches use integer membership
                    // and the created-date index without sorting every full note.
                    try execute("DELETE FROM notes")
                    try rows("SELECT rowid,payload FROM captures") { statement in
                        let capture = try JSONDecoder().decode(Capture.self, from: blob(statement,1))
                        try execute("INSERT INTO notes(rowid,id,text) VALUES(?,?,?)", [column(statement,0),capture.id.uuidString,capture.text])
                    }
                    try put("fts.rowids.aligned", Data([1]))
                }
            }
            #if os(iOS)
            // The containing directory protects SQLite, its WAL and SHM sidecars.
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.deletingLastPathComponent().path)
            for suffix in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: path + suffix) {
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: path + suffix)
            }
            #endif
        } catch { sqlite3_close(db); db = nil; throw error }
    }

    public func read(captureLimit: Int? = nil) throws -> Vault {
        try withStore {
            // One read transaction keeps metadata and sources at one generation.
            try execute("BEGIN DEFERRED")
            do { let vault = try readCurrent(captureLimit: captureLimit); try execute("COMMIT"); return vault }
            catch { try? execute("ROLLBACK"); throw error }
        }
    }
    private func readCurrent(captureLimit: Int? = nil) throws -> Vault {
        var vault = try JSONDecoder().decode(Vault.self, from: value("vault") ?? Data())
        let sql = captureLimit.map { "SELECT payload FROM captures ORDER BY created DESC, id LIMIT \(max(0,$0))" } ?? "SELECT payload FROM captures ORDER BY created, rowid"
        try rows(sql) { stmt in
            vault.captures.append(try JSONDecoder().decode(Capture.self, from: blob(stmt, 0)))
        }
        return vault
    }

    /// Original inspection loads one source even when the keyboard snapshot is bounded.
    public func capture(id: UUID) throws -> Capture? {
        try withStore {
            var capture: Capture?
            try rows("SELECT payload FROM captures WHERE id=?", [id.uuidString]) {
                capture = try JSONDecoder().decode(Capture.self, from: blob($0,0))
            }
            return capture
        }
    }

    // Existing rich-text/checklist/reminder callers retain their mutation API.
    // Only changed sources are reindexed; no full-index rebuild on each save.
    @discardableResult
    public func update(captureIDs: [UUID]? = nil, captureLimit: Int? = nil,
                       _ mutate: (inout Vault) throws -> Void) throws -> Vault {
        try withStore { try transaction {
            // Known-source mutations load only those originals and the shared
            // metadata. The result uses the caller's normal bounded window.
            var old = try readCurrent(captureLimit: captureIDs == nil ? nil : 0)
            if let captureIDs { old.captures = try Set(captureIDs).compactMap { try capture(id: $0) } }
            var latest = old
            try mutate(&latest)
            let previous = Dictionary(uniqueKeysWithValues: old.captures.map { ($0.id, $0) })
            let current = Set(latest.captures.map(\.id))
            var affected = Set<UUID>()
            for capture in latest.captures where previous[capture.id] != capture {
                let (note, parent) = try identity(capture.id)
                let source = Capture(id: note, text: capture.text, richText: capture.richText, checklist: capture.checklist, createdAt: capture.createdAt)
                try queue(NoteRevision(noteID: note, capture: source, parents: parent))
                affected.insert(note)
            }
            for capture in old.captures where !current.contains(capture.id) {
                let (note, parents) = try identity(capture.id)
                // A displayed copy can fold equivalent heads. Delete only those
                // heads; unseen edits and different conflict copies stay live.
                try queue(NoteRevision(noteID: note, capture: nil, parents: parents))
                affected.insert(note)
            }
            for note in affected { try materialize(note) }
            var metadata = latest; metadata.captures = []
            try put("vault", JSONEncoder().encode(metadata))
            return try readCurrent(captureLimit: captureLimit)
        } }
    }

    /// Capture's hot path does not decode or rewrite 10k older originals.
    public func append(_ capture: Capture) throws {
        try withStore { try transaction {
            let (note, parent) = try identity(capture.id)
            let source = Capture(id: note, text: capture.text, richText: capture.richText, checklist: capture.checklist, createdAt: capture.createdAt)
            try queue(NoteRevision(noteID: note, capture: source, parents: parent))
            try materialize(note)
        } }
    }

    // FTS5 ranks on disk and returns only a bounded page of original records.
    // Deletion signatures restrict typo candidates without scanning the corpus.
    public func search(_ query: String, limit: Int = 30, openTasks: Bool = false) throws -> [SearchHit] {
        try withStore {
            let words = Self.words(String(query.prefix(256))).prefix(12)
            // Eligibility is applied before pagination, so older unfinished lists
            // remain discoverable behind a page of ordinary captures.
            let taskFilter = openTasks ? " AND EXISTS (SELECT 1 FROM json_each(c.payload,'$.checklist') item WHERE json_extract(item.value,'$.complete')=0)" : ""
            if words.isEmpty {
                var hits: [SearchHit] = []
                try rows("SELECT c.payload FROM captures c WHERE 1=1\(taskFilter) ORDER BY c.created DESC,c.id LIMIT ?", [String(max(1, min(limit, 100)))]) { stmt in
                    let capture = try JSONDecoder().decode(Capture.self, from: blob(stmt, 0))
                    if !openTasks || (!capture.checklist.isEmpty && !capture.allItemsComplete) { hits.append(SearchHit(capture: capture, highlightedText: capture.text)) }
                }
                return hits
            }
            var clauses: [String] = []
            var highlightTerms: [String] = []
            for word in words {
                var alternatives = ["\"\(word)\"*"]
                highlightTerms.append(word)
                var knownPrefix = false
                try rows("SELECT term FROM vocabulary WHERE term >= ? AND term < ? LIMIT 1", [word, word + "\u{10FFFF}"]) { _ in knownPrefix = true }
                if word.count >= 4 && !knownPrefix {
                    var candidates = Set<String>()
                    for signature in Self.signatures(word) {
                        try rows("SELECT word FROM spellings WHERE term=? LIMIT 64", [signature]) { candidates.insert(column($0, 0)) }
                    }
                    for candidate in candidates.sorted() where candidate != word && Self.near(word, candidate) {
                        alternatives.append("\"\(candidate)\"")
                        highlightTerms.append(candidate)
                        if alternatives.count == 12 { break }
                    }
                }
                clauses.append("(" + alternatives.joined(separator: " OR ") + ")")
            }
            let expression = clauses.joined(separator: " AND ")
            var candidateCount = 0
            try rows("SELECT count(*) FROM (SELECT rowid FROM notes WHERE notes MATCH ? LIMIT 501)", [expression]) { candidateCount = Int(column($0,0)) ?? 0 }
            if candidateCount > 500 {
                // Common clues have weak specificity. Prefer the newest originals
                // using an indexed recent scan over integer FTS membership. This
                // avoids scoring/sorting all 10k notes for each early keystroke.
                var hits: [SearchHit] = []
                let membership = words.allSatisfy { $0.count == 2 }
                    ? "EXISTS (SELECT 1 FROM notes WHERE notes.rowid=c.rowid AND notes MATCH ?)"
                    : "c.rowid IN (SELECT rowid FROM notes WHERE notes MATCH ?)"
                try rows("""
                    SELECT c.payload FROM captures c INDEXED BY captures_created
                    WHERE \(membership)\(taskFilter)
                    ORDER BY c.created DESC,c.id LIMIT ?
                    """, [expression,String(max(1,min(limit,100)))]) { statement in
                    let capture = try JSONDecoder().decode(Capture.self, from: blob(statement,0))
                    if !openTasks || (!capture.checklist.isEmpty && !capture.allItemsComplete) {
                        hits.append(SearchHit(capture: capture, highlightedText: Self.mark(capture.text, terms: highlightTerms)))
                    }
                }
                return hits
            }
            var hits: [SearchHit] = []
            // All remembered tokens must match, with prefix/one-edit alternatives.
            try rows("""
                SELECT c.payload, highlight(notes,1,'⟦','⟧') FROM notes
                JOIN captures c ON c.rowid=notes.rowid WHERE notes MATCH ?\(taskFilter)
                ORDER BY rank LIMIT ?
                """, [expression, String(max(1, min(limit, 100)))]) { stmt in
                let capture = try JSONDecoder().decode(Capture.self, from: blob(stmt, 0))
                if !openTasks || (!capture.checklist.isEmpty && !capture.allItemsComplete) { hits.append(SearchHit(capture: capture, highlightedText: column(stmt, 1))) }
            }
            return hits
        }
    }

    // Broad-result previews preserve wording and punctuation, adding delimiters
    // only around matching original tokens. Full source text is never truncated.
    private static func mark(_ text: String, terms: [String]) -> String {
        var output = "", token = ""
        func flush() {
            guard !token.isEmpty else { return }
            let normalized = words(token).first ?? ""
            output += terms.contains(where: { normalized.hasPrefix($0) }) ? "⟦" + token + "⟧" : token
            token = ""
        }
        for character in text.prefix(500) {
            if character.isLetter || character.isNumber { token.append(character) }
            else { flush(); output.append(character) }
        }
        flush()
        return output
    }

    private static func words(_ text: String) -> [String] {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }
    private static func signatures(_ word: String) -> Set<String> {
        let chars = Array(word.prefix(64))
        var result: Set<String> = [String(chars)]
        for i in chars.indices { var copy = chars; copy.remove(at: i); result.insert(String(copy)) }
        return result
    }
    // One insertion/deletion/substitution or adjacent transposition. This bounded
    // comparison is applied only to dictionary candidates, never every note.
    private static func near(_ a: String, _ b: String) -> Bool {
        let x = Array(a), y = Array(b)
        guard abs(x.count-y.count) <= 1 else { return false }
        if x.count == y.count {
            let differences = x.indices.filter { x[$0] != y[$0] }
            if differences.count <= 1 { return true }
            if differences.count == 2 {
                let i = differences[0], j = differences[1]
                return j == i+1 && x[i] == y[j] && x[j] == y[i]
            }
            return false
        }
        let shorter = x.count < y.count ? x : y, longer = x.count < y.count ? y : x
        var i = 0, j = 0
        while i < shorter.count && j < longer.count {
            if shorter[i] == longer[j] { i += 1; j += 1 }
            else { j += 1; if j-i > 1 { return false } }
        }
        return true
    }

    private func write(_ capture: Capture) throws {
        try execute("DELETE FROM notes WHERE rowid IN (SELECT rowid FROM captures WHERE id=?)", [capture.id.uuidString])
        try execute("INSERT OR REPLACE INTO captures(id,payload,created) VALUES(?,?,?)", [capture.id.uuidString, String(data: try JSONEncoder().encode(capture), encoding: .utf8)!, String(capture.createdAt.timeIntervalSince1970)])
        try execute("INSERT INTO notes(rowid,id,text) SELECT rowid,id,? FROM captures WHERE id=?", [capture.text,capture.id.uuidString])
        for word in Set(Self.words(capture.text)) where word.count >= 4 {
            for signature in Self.signatures(word) { try execute("INSERT OR IGNORE INTO spellings(term,word) VALUES(?,?)", [signature,word]) }
        }
    }
    private func remove(_ id: UUID) throws {
        try execute("DELETE FROM notes WHERE rowid IN (SELECT rowid FROM captures WHERE id=?)", [id.uuidString])
        try execute("DELETE FROM captures WHERE id=?", [id.uuidString])
    }

    // Public sync state stays in the same durable database as its mutation queue.
    public func syncValue(_ key: String) throws -> Data? { try withStore { try value("sync." + key) } }
    public func setSyncValue(_ key: String, _ data: Data) throws { try withStore { try put("sync." + key, data) } }
    public func bindSyncAccount(_ account: String) throws {
        try withStore { try transaction {
            let identity = Data(account.utf8)
            if let old = try value("sync.account"), old != identity { throw SyncFailure.accountChanged }
            try put("sync.account", identity)
        } }
    }
    public func pendingRevisions() throws -> [NoteRevision] {
        try withStore { try revisions("SELECT payload FROM revisions WHERE pending=1 ORDER BY rowid ASC LIMIT 100") }
    }
    public func acknowledge(_ ids: [UUID]) throws {
        try withStore { try transaction { for id in ids { try execute("UPDATE revisions SET pending=0 WHERE id=?", [id.uuidString]) } } }
    }
    public func merge(_ incoming: [NoteRevision]) throws {
        try withStore { try transaction {
            for revision in incoming {
                try execute("INSERT OR IGNORE INTO revisions(id,note,payload,pending) VALUES(?,?,?,0)", [revision.id.uuidString, revision.noteID.uuidString, String(data: try JSONEncoder().encode(revision), encoding: .utf8)!])
            }
            for note in Set(incoming.map(\.noteID)) { try materialize(note) }
        } }
    }
    private func queue(_ revision: NoteRevision) throws {
        try execute("INSERT INTO revisions(id,note,payload,pending) VALUES(?,?,?,1)", [revision.id.uuidString, revision.noteID.uuidString, String(data: try JSONEncoder().encode(revision), encoding: .utf8)!])
    }
    private func revisions(_ sql: String, _ args: [String] = []) throws -> [NoteRevision] {
        var output: [NoteRevision] = []
        try rows(sql,args) { output.append(try JSONDecoder().decode(NoteRevision.self, from: blob($0,0))) }
        return output
    }
    // Projection membership retains every equal branch, so the next edit or
    // delete advances all heads represented by the displayed original.
    private func identity(_ id: UUID) throws -> (UUID, [UUID]) {
        var note = id
        var parents: [UUID] = []
        try rows("SELECT note FROM projections WHERE id=?", [id.uuidString]) {
            note = UUID(uuidString: column($0,0)) ?? id
        }
        try rows("SELECT revision FROM projectionRevisions WHERE id=? ORDER BY revision", [id.uuidString]) {
            if let revision = UUID(uuidString: column($0,0)) { parents.append(revision) }
        }
        return (note, parents)
    }

    private func materialize(_ note: UUID) throws {
        let all = try revisions("SELECT payload FROM revisions WHERE note=?", [note.uuidString])
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        // CloudKit batches are unordered. Store incomplete revisions durably,
        // but expose only chains whose parents are present in this same note.
        // Memoization also leaves malformed cycles unprojected without looping.
        var complete: [UUID: Bool] = [:]
        func hasAncestry(_ id: UUID) -> Bool {
            if let known = complete[id] { return known }
            guard let revision = byID[id] else { return false }
            complete[id] = false
            let result = revision.parents.allSatisfy { hasAncestry($0) }
            complete[id] = result
            return result
        }
        let ready = all.filter { hasAncestry($0.id) }
        let superseded = Set(ready.flatMap(\.parents))
        let heads = ready.filter { !superseded.contains($0.id) && $0.capture != nil }
            .sorted { $0.id.uuidString < $1.id.uuidString }
        var groups: [[NoteRevision]] = []
        for revision in heads {
            if let index = groups.firstIndex(where: { $0[0].capture == revision.capture }) {
                groups[index].append(revision)
            } else { groups.append([revision]) }
        }
        var projected: [UUID] = []
        try rows("SELECT id FROM projections WHERE note=?", [note.uuidString]) {
            if let id = UUID(uuidString: column($0,0)) { projected.append(id) }
        }
        try remove(note)
        for id in projected {
            try remove(id)
            try execute("DELETE FROM projectionRevisions WHERE id=?", [id.uuidString])
        }
        try execute("DELETE FROM projections WHERE note=?", [note.uuidString])
        for (index, group) in groups.enumerated() {
            let revision = group[0]
            guard let source = revision.capture else { continue }
            let capture = Capture(id: index == 0 ? note : revision.id, text: source.text, richText: source.richText, checklist: source.checklist, createdAt: source.createdAt)
            try write(capture)
            try execute("INSERT INTO projections(id,note,revision) VALUES(?,?,?)", [capture.id.uuidString,note.uuidString,revision.id.uuidString])
            for head in group {
                try execute("INSERT INTO projectionRevisions(id,revision) VALUES(?,?)", [capture.id.uuidString,head.id.uuidString])
            }
        }
    }

    private func transaction<T>(_ work: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do { let result = try work(); try execute("COMMIT"); return result }
        catch { try? execute("ROLLBACK"); throw error }
    }
    private func value(_ key: String) throws -> Data? {
        var data: Data?
        try rows("SELECT value FROM metadata WHERE key=?", [key]) { data = blob($0,0) }
        return data
    }
    private func put(_ key: String, _ data: Data) throws {
        // Metadata and encoded records are UTF-8 JSON; engine state can be binary.
        try execute("INSERT OR REPLACE INTO metadata(key,value) VALUES(?,?)", [key, data.base64EncodedString()])
    }
    private func blob(_ statement: OpaquePointer, _ index: Int32) -> Data {
        let text = column(statement,index)
        // Only metadata uses base64; record JSON begins with a brace.
        return text.hasPrefix("{") ? Data(text.utf8) : (Data(base64Encoded: text) ?? Data(text.utf8))
    }
    private func column(_ statement: OpaquePointer, _ index: Int32) -> String {
        guard let chars = sqlite3_column_text(statement,index) else { return "" }
        return String(cString: chars)
    }
    private func rows(_ sql: String, _ args: [String] = [], _ body: (OpaquePointer) throws -> Void) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { throw failure() }
        defer { sqlite3_finalize(stmt) }
        for (i,arg) in args.enumerated() { guard sqlite3_bind_text(stmt,Int32(i+1),arg,-1,transient) == SQLITE_OK else { throw failure() } }
        while true {
            let code = sqlite3_step(stmt)
            if code == SQLITE_DONE { return }
            guard code == SQLITE_ROW else { throw failure() }
            try body(stmt)
        }
    }
    private func execute(_ sql: String, _ args: [String] = []) throws {
        if args.isEmpty {
            guard sqlite3_exec(db,sql,nil,nil,nil) == SQLITE_OK else { throw failure() }
        } else { try rows(sql,args) { _ in } }
    }
    private func failure() -> NSError {
        NSError(domain:"MindMachine.Storage", code:Int(sqlite3_errcode(db)), userInfo:[NSLocalizedDescriptionKey: String(cString: sqlite3_errmsg(db))])
    }
}
