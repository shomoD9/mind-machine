/* Durable SQLite source/index shared by the companion, keyboard and Mac through
 VaultModel. The legacy JSON URL remains the migration source and is never removed.
 Every acknowledged write commits originals, FTS and replication revisions together. */
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
    // Saved; a bounded 2 MiB page cache avoids an in-memory keyboard-sized index.
    private func open() throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let path = url.deletingPathExtension().appendingPathExtension("sqlite").path
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else { throw failure() }
        do {
            sqlite3_busy_timeout(db, 5000)
            try execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA fullfsync=ON; PRAGMA cache_size=-2048; PRAGMA secure_delete=ON;")
            try execute("""
                CREATE TABLE IF NOT EXISTS metadata(key TEXT PRIMARY KEY, value BLOB NOT NULL);
                CREATE TABLE IF NOT EXISTS captures(id TEXT PRIMARY KEY, payload BLOB NOT NULL, created REAL NOT NULL);
                CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(id UNINDEXED, text, tokenize='unicode61 remove_diacritics 2', prefix='2 3 4');
                CREATE VIRTUAL TABLE IF NOT EXISTS vocabulary USING fts5vocab(notes, 'row');
                CREATE TABLE IF NOT EXISTS revisions(id TEXT PRIMARY KEY, note TEXT NOT NULL, payload BLOB NOT NULL, pending INTEGER NOT NULL);
                CREATE INDEX IF NOT EXISTS revisions_note ON revisions(note);
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

    public func read() throws -> Vault {
        try withStore {
            // One read transaction keeps metadata and sources at one generation.
            try execute("BEGIN DEFERRED")
            do { let vault = try readCurrent(); try execute("COMMIT"); return vault }
            catch { try? execute("ROLLBACK"); throw error }
        }
    }
    private func readCurrent() throws -> Vault {
        var vault = try JSONDecoder().decode(Vault.self, from: value("vault") ?? Data())
        try rows("SELECT payload FROM captures ORDER BY created, rowid") { stmt in
            vault.captures.append(try JSONDecoder().decode(Capture.self, from: blob(stmt, 0)))
        }
        return vault
    }

    // Existing rich-text/checklist/reminder callers retain their mutation API.
    // Only changed sources are reindexed; no full-index rebuild on each save.
    @discardableResult
    public func update(_ mutate: (inout Vault) throws -> Void) throws -> Vault {
        try withStore { try transaction {
            let old = try readCurrent()
            var latest = old
            try mutate(&latest)
            let previous = Dictionary(uniqueKeysWithValues: old.captures.map { ($0.id, $0) })
            let current = Set(latest.captures.map(\.id))
            for capture in latest.captures where previous[capture.id] != capture {
                try write(capture)
                try queue(NoteRevision(capture: capture, parents: try heads(capture.id).map(\.id)))
            }
            for capture in old.captures where !current.contains(capture.id) {
                try remove(capture.id)
                try queue(NoteRevision(noteID: capture.id, capture: nil, parents: try heads(capture.id).map(\.id)))
            }
            var metadata = latest; metadata.captures = []
            try put("vault", JSONEncoder().encode(metadata))
            return latest
        } }
    }

    /// Capture's hot path does not decode or rewrite 10k older originals.
    public func append(_ capture: Capture) throws {
        try withStore { try transaction {
            try write(capture)
            try queue(NoteRevision(capture: capture, parents: try heads(capture.id).map(\.id)))
        } }
    }

    // FTS5 ranks on disk and returns only a bounded page of original records.
    // Deletion signatures restrict typo candidates without scanning the corpus.
    public func search(_ query: String, limit: Int = 30, openTasks: Bool = false) throws -> [SearchHit] {
        try withStore {
            let words = Self.words(String(query.prefix(256))).prefix(12)
            if words.isEmpty {
                var hits: [SearchHit] = []
                try rows("SELECT payload FROM captures ORDER BY created DESC, id LIMIT ?", [String(max(1, min(limit, 100)))]) { stmt in
                    let capture = try JSONDecoder().decode(Capture.self, from: blob(stmt, 0))
                    if !openTasks || (!capture.checklist.isEmpty && !capture.allItemsComplete) { hits.append(SearchHit(capture: capture, highlightedText: capture.text)) }
                }
                return hits
            }
            var clauses: [String] = []
            for word in words {
                var alternatives = ["\"\(word)\"*"]
                if word.count >= 4 {
                    var candidates = Set<String>()
                    for signature in Self.signatures(word) {
                        try rows("SELECT word FROM spellings WHERE term=? LIMIT 64", [signature]) { candidates.insert(column($0, 0)) }
                    }
                    for candidate in candidates.sorted() where candidate != word && Self.near(word, candidate) {
                        alternatives.append("\"\(candidate)\"")
                        if alternatives.count == 12 { break }
                    }
                }
                clauses.append("(" + alternatives.joined(separator: " OR ") + ")")
            }
            var hits: [SearchHit] = []
            // All remembered tokens must match, with prefix/one-edit alternatives.
            try rows("""
                SELECT c.payload, highlight(notes,1,'⟦','⟧') FROM notes
                JOIN captures c ON c.id=notes.id WHERE notes MATCH ?
                ORDER BY bm25(notes), c.created DESC, c.id LIMIT ?
                """, [clauses.joined(separator: " AND "), String(max(1, min(limit, 100)))]) { stmt in
                let capture = try JSONDecoder().decode(Capture.self, from: blob(stmt, 0))
                if !openTasks || (!capture.checklist.isEmpty && !capture.allItemsComplete) { hits.append(SearchHit(capture: capture, highlightedText: column(stmt, 1))) }
            }
            return hits
        }
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
        try execute("INSERT OR REPLACE INTO captures(id,payload,created) VALUES(?,?,?)", [capture.id.uuidString, String(data: try JSONEncoder().encode(capture), encoding: .utf8)!, String(capture.createdAt.timeIntervalSince1970)])
        try execute("DELETE FROM notes WHERE id=?", [capture.id.uuidString])
        try execute("INSERT INTO notes(id,text) VALUES(?,?)", [capture.id.uuidString, capture.text])
        for word in Set(Self.words(capture.text)) where word.count >= 4 {
            for signature in Self.signatures(word) { try execute("INSERT OR IGNORE INTO spellings(term,word) VALUES(?,?)", [signature,word]) }
        }
    }
    private func remove(_ id: UUID) throws {
        try execute("DELETE FROM captures WHERE id=?", [id.uuidString])
        try execute("DELETE FROM notes WHERE id=?", [id.uuidString])
    }

    // Public sync state stays in the same durable database as its mutation queue.
    public func syncValue(_ key: String) throws -> Data? { try withStore { try value("sync." + key) } }
    public func setSyncValue(_ key: String, _ data: Data) throws { try withStore { try put("sync." + key, data) } }
    public func pendingRevisions() throws -> [NoteRevision] {
        try withStore { try revisions("SELECT payload FROM revisions WHERE pending=1 ORDER BY rowid") }
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
    private func heads(_ note: UUID) throws -> [NoteRevision] {
        let all = try revisions("SELECT payload FROM revisions WHERE note=?", [note.uuidString])
        let superseded = Set(all.flatMap(\.parents))
        return all.filter { !superseded.contains($0.id) }.sorted { $0.id.uuidString < $1.id.uuidString }
    }
    private func materialize(_ note: UUID) throws {
        let all = try revisions("SELECT payload FROM revisions WHERE note=?", [note.uuidString])
        // A durable tombstone dominates stale replicas. Concurrent originals stay
        // as deterministic revision-ID copies rather than last-writer data loss.
        try remove(note)
        for revision in all { try remove(revision.id) }
        guard !all.contains(where: { $0.capture == nil }) else { return }
        for (index, revision) in try heads(note).enumerated() {
            guard let source = revision.capture else { continue }
            let capture = Capture(id: index == 0 ? note : revision.id, text: source.text, richText: source.richText, checklist: source.checklist, createdAt: source.createdAt)
            try write(capture)
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
