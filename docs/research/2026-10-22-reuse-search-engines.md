# Reusing search engines

Use Omnisearch's underlying MiniSearch as a credible lexical adapter candidate. A native Mac probe passed. Compare its device memory and retrieval quality with SQLite FTS5 before selecting the production adapter. Both need a separate semantic encoder for paraphrases.

Researched 22 October 2026 using upstream repositories, manifests, documentation and a synthetic executable. No production dependency was adopted. This extends [the retrieval architecture report](2026-10-22-fast-private-retrieval.md).

## Omnisearch and the reusable library

[Omnisearch](https://github.com/scambier/obsidian-omnisearch/tree/0a4e93b2ed155b84c3fe89f6d2d19c5a8c171a87) is an Obsidian plugin with weighted full-text ranking, fuzzy matching and integration for extracted attachment text. Its wrapper depends on the host and browser storage. An optional HTTP API still needs that host running. Forking the plugin would leave our keyboard's offline storage, native lifecycle and UI to solve. Its GPL-3.0 distribution terms require a deliberate licensing decision if copying covered code. This does not prohibit commercial use. [Manifest](https://github.com/scambier/obsidian-omnisearch/blob/0a4e93b2ed155b84c3fe89f6d2d19c5a8c171a87/package.json), [license](https://github.com/scambier/obsidian-omnisearch/blob/0a4e93b2ed155b84c3fe89f6d2d19c5a8c171a87/LICENSE).

[MiniSearch](https://github.com/lucaong/minisearch) provides the reusable in-memory JavaScript engine, with BM25-family ranking, field weighting, prefix/typo matching, incremental changes and serialization. It is MIT licensed. We can use that library without copying the Obsidian plugin. Our JavaScriptCore harness tested 7.1.0, the version pinned by the inspected Omnisearch 1.31.0 manifest. Preserve its notices if shipped. [Library documentation/source](https://github.com/lucaong/minisearch), [native probe evidence](../verification/minisearch-native-probe-2026-10-22.md).

BM25 scores remembered words according to their frequency, rarity and document length. Fuzzy matching tolerates spelling changes. Semantic retrieval encodes meaning so a query can match different wording. Our probe found the birthday fixture by exact/prefix/typo queries; a no-overlap paraphrase returned empty. A lexical engine alone cannot meet the requested semantic experience.

## Native shortlist

| Component | Reusable role and licence | Fit and remaining work |
| --- | --- | --- |
| [SQLite FTS5](https://www.sqlite.org/fts5.html) through [GRDB](https://github.com/groue/GRDB.swift) | Persistent lexical index/BM25; SQLite public domain, GRDB MIT | First native baseline. Source and lexical changes can share a transaction. Prefix search exists; typo tolerance needs additional handling. Verify bundled SQLite version, tokenizer, protected files and selected GRDB/encrypted-build compatibility. |
| [MiniSearch](https://github.com/lucaong/minisearch) | MIT lexical engine, hosted through JavaScriptCore | Successful standalone Mac bridge. 10k synthetic-query p95 0.12–3.81 ms in the timed run. Whole-process peak RSS about 95 MiB includes two indexes and fixtures; test actual extension memory. Separate index persistence/reconciliation remains. |
| [USearch](https://github.com/unum-cloud/usearch) | Apache-2.0 vector similarity index | Actual Swift/C package, with iOS 15/macOS 12 minimums and NumKong dependency. Candidate if cached exact-vector search becomes too expensive. It consumes vectors; an embedding model is still required. [Manifest](https://github.com/unum-cloud/usearch/blob/main/Package.swift), [licence](https://github.com/unum-cloud/usearch/blob/main/LICENSE). |
| [sqlite-vec](https://github.com/asg017/sqlite-vec) | MIT/Apache-2.0 vector extension in C | Keeps vectors beside SQLite records. Pre-v1 API and iOS static integration/encrypted database compatibility require a pilot. It also needs an encoder. |
| [Tantivy](https://github.com/quickwit-oss/tantivy) | MIT Rust full-text engine | Useful future alternative for a shared Rust core. Swift bridge, iOS packaging and extension footprint remain unverified here. No evidence justifies a whole backend rewrite for this app yet. |

These are component capabilities from primary sources, without comparative application benchmarks. The MiniSearch experiment is the only new executable library probe in this pass. No ANN or full-text candidate has passed our real-device acceptance suite. Upstream main branches must be pinned and their complete dependency/licence graph inspected before integration.

## Proposed composition

Keep one retrieval interface serving keyboard Find, Mac live search and Chat. Apply committed source changes to a local lexical index; publish lexical matches while a separate small query encoder computes semantic candidates. Precompute document/chunk vectors on capture/change, outside typing/rendering. Fuse and deduplicate candidates using judged queries. Cancel obsolete work and reject stale request/source generations before publication.

The local source database can use GRDB even if MiniSearch wins the lexical comparison. SQLiteData builds on GRDB but is a separate sync/storage wrapper; adopting one does not force adopting every other layer. Keep model/runtime/vector-index choices behind adapters. Search must not wait for CloudKit or an Ollama process. Protect every derived index and remove its entries during Forget. See the [proposed interface and acceptance budgets](2026-10-22-fast-private-retrieval.md#proposed-module-contract).

**Next decision:** benchmark FTS5 and MiniSearch on the same realistic corpus in an actual keyboard extension, then choose one lexical implementation. Evaluate existing NLEmbedding and a compact multilingual model independently. Avoid installing several vector engines before profiling shows a need.
