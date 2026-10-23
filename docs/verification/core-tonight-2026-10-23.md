# Core verification — 23 October 2026

The shared store, search and private replication adapter build in macOS CI. The signed two-device workflow and physical iPhone keyboard acceptance remain founder checks in [TESTING-TONIGHT](../TESTING-TONIGHT.md).

## Engine decision

Ship system SQLite FTS5. It keeps originals, index updates and the pending revision in one durable transaction, supports independent companion/keyboard processes, and uses a 2 MiB page cache rather than loading the corpus into JavaScriptCore. Prefix matching is native; an indexed deletion dictionary supplies one-edit/adjacent-transposition fallback when a prefix is absent. Specific queries use BM25, while clues matching over 500 sources prefer recent originals through a created-date index. Results contain exact originals and separate highlighted previews. The keyboard retains 100 recent captures, loads inspected originals by ID and renders a 30-result page after a 25ms query debounce. Deferred reminder reconciliation reads only its linked sources.

[SQLite's FTS5 documentation](https://sqlite.org/fts5.html) describes the reused ranking/prefix/highlight implementation. SQLite is public domain and supplied by the Apple SDK; no extra database or JavaScript runtime is downloaded into the product. Attribution is in THIRD_PARTY_NOTICES.

## Same-corpus comparison

[Run 39912435428](https://github.com/shomoD9/mind-machine/actions/runs/39912435428) passed iPhone/keyboard and Mac builds, 28 package tests (one Debug-only performance skip; the Release benchmark ran separately), the expanded search budget, process durability and fake-cloud replication. An earlier run 39911939501 required a rerun of the separate Mac animation sampler after it missed an intermediate frame; no Mac window code was changed here.

Both standalone processes used the same 10,000 generated text notes and 240 queries: blank, p, pr, teles, telescpoe, passport, birthd, gardne, item9876, recipe project, nohitsxyz. Each returns up to 30 texts. Notes repeat ten topics with unique project numbers, reference tokens and URLs. No personal vault was accessed. Runner: GitHub macos-26, Xcode 26.2, arm64 Release.

| Measurement | SQLite FTS5 | MiniSearch 7.1.0 / JavaScriptCore |
| --- | ---: | ---: |
| Isolated query p95 | 3.677 ms | 21.536 ms |
| Whole-process peak RSS | 11.50 MiB | 81.38 MiB |
| Cold setup | 22.78 ms, open persisted database + first query | 884.46 ms, runtime + build index |
| Corpus resident in runtime | Bounded source/result pages + SQLite cache | Stored text + complete JS index |

These setup operations differ: MiniSearch serialized-index reload was not measured here. Ranking/fuzzy semantics also differ: MiniSearch uses BM25-family ranking with prefix and fuzzy 0.2 plus AND combination; our broad-result policy prefers recency and one-edit fallback. MiniSearch missed gardne in the earlier same-corpus run, while the FTS5 adapter finds garden by adjacent transposition. This is a product integration comparison, not a universal library-speed or equal-relevance claim. FTS5 wins this measured keyboard-oriented memory/latency choice.

An earlier narrower comparison on [run 39910611792](https://github.com/shomoD9/mind-machine/actions/runs/39910611792) measured FTS5 p95 2.537 ms/11.17 MiB peak RSS versus MiniSearch 11.138 ms/80.27 MiB. The final corpus adds early typing cases instead of hiding them. MiniSearch's MIT bundle is downloaded only to runner temporary storage; its published SHA-512 and UMD SHA-256 are pinned/verified by `fetch_minisearch_probe.py`, with no npm install/scripts. Production contains no MiniSearch/Obsidian code.

## Budgets and durability

On run 39912435428, the public saved-vault benchmark measured query p95 **3.813 ms**, one-letter p p95 **3.936 ms**, two-letter pr **2.670 ms**, and durable-append p95 **7.767 ms**. Whole XCTest-process peak RSS was **52.73 MiB**, including fixture construction and testing frameworks; that is a different process from the isolated 11.50 MiB source/index query process. Query p95 is asserted below **10 ms** in CI, with per-query samples printed and artifacts uploaded. Save timings include FULL synchronous commit and fullfsync; there is no save-speed assertion.

The initial search test failed at 20.404 ms. Optimized FTS rank ordering removed unnecessary sorting/fuzzy expansion. Expanding the suite to broad prefixes then exposed a 17.291 ms p95 failure, fixed by indexed recency ranking/integer FTS membership. Both failures and fixes are recorded in the journal; the threshold stayed 10 ms.

The process probe acknowledged forty committed notes, sent SIGKILL, reopened the database and recovered **40/40 acknowledged originals**. Two independent concurrent writer processes then saved **200/200 new originals** without overwriting one another. WAL/FULL/fullfsync and a single source/index/outbox transaction are exercised through the real store. A thrown mutation leaves the original and pending revision unchanged. JSON migration preserves source bytes; decode errors remain errors.

## Replication evidence and limits

The fake-cloud tests transport only AES-256-GCM envelopes and verify offline concurrent edits converge with both originals, conflict-copy edits survive old-parent replay, repeated delivery is idempotent, tombstones prevent stale resurrection, wrong keys fail and account changes retain local notes while rejecting exchange. The production CKSyncEngine adapter compiles against both Apple SDKs and uses the private database/custom zone plus `CKRecord.encryptedValues` around the app ciphertext. Shared-key setup is explicit and does not auto-create divergent device keys.

[Apple documents encrypted fields](https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues) and their Advanced Data Protection condition; app-side AES-GCM supplies an additional service-unreadable boundary independently of that setting. The owner must preserve the recovery key. [Apple documents shared Keychain access groups](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps); identical signing/team/capabilities are necessary for phone/keyboard/Mac access.

No physical keyboard process, Jetsam termination limit, real host typing latency or live CloudKit exchange was measured on this Linux machine. The extension reports its actual Mach physical footprint and [OS-provided headroom](https://developer.apple.com/documentation/os/os_proc_available_memory) into the App Group; companion setup displays the timestamped report. Founder acceptance should require at least 15 MiB headroom under their vault/sync load. The isolated process numbers above do not establish that margin. No universal extension limit or Apple typing parity is claimed. Semantic/paraphrase retrieval, image/voice ingestion and production-schema deployment remain gaps. Local notes/index are sandbox/file-protected; this is not a database-encryption implementation.

## Reproduce on Mac

```sh
swift test --package-path native
swift test -c release --package-path native --filter SearchPerformanceTests
swift build -c release --package-path native
python3 native/Scripts/verify_vault_processes.py native/.build/release/VaultIntegrityProbe
```

The workflow records exact standalone comparison commands and uploads `search-benchmark.txt` and `search-comparison.txt`. Re-run `native-ci` from GitHub Actions to use the same macOS/Xcode configuration. No signing secret or Team ID is needed for those checks.
