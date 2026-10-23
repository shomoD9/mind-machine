# Fast private retrieval

Use a device-local lexical index, precomputed semantic vectors, and asynchronous query updates behind one retrieval module. Publish useful word matches first, then improve the results with semantic matches. Keep inference servers outside the search dependency graph.

Research checked 22 October 2026 against upstream documentation and source. This is a recommendation and benchmark plan. No candidate was integrated or benchmarked in this pass; no latency or semantic-quality result is established. Source inspection used repository commit `5ebb61be52a403942c1933843a9a06e4e52df3c7`.

## Current implementation

- [`VaultModel.results`](../../native/Sources/MindMachineUI/VaultModel.swift:110) runs on the main actor. For each nonempty query, it embeds the query and every capture, computes cosine similarity, then invokes an in-memory filter and sort. Document embeddings are recomputed on every call. Only the first 2,500 characters of each capture contribute semantic evidence.
- [`Vault.findCaptures`](../../native/Sources/MindMachineCore/Vault.swift:107) counts substring word matches and combines them with a supplied semantic score. This is the current lexical heuristic; there is no BM25 index. Retained chat messages are outside this search path.
- [`WorkspaceView`](../../native/Sources/MindMachineUI/WorkspaceView.swift:74) calls `results` for the list and again for the empty-state check. The keyboard does the same. SwiftUI observes query changes; the keyboard's [`textViewDidChange`](../../native/Apps/Keyboard/KeyboardViewController.swift:525) only retains its draft. Keyboard results require another render trigger, such as Search.
- [`VaultFile`](../../native/Sources/MindMachineCore/VaultFile.swift) reads and rewrites a coordinated JSON document. This remains the current source of truth; a new derived index must handle changes from both companion and extension.

These code observations explain work that grows with the corpus. They do not measure its current duration. The earlier [component survey](../../.scratch/scattered-ambitious-pitch/research/14-open-source-capture-organization-retrieval.md) identified FTS5 and sqlite-vec as candidates and explicitly left their performance untested.

## Lexical candidate

BM25 ranks documents using the words in a query, their frequency and rarity, and document length. It helps recover names and remembered wording; semantic vectors add paraphrase matches. SQLite FTS5 supplies BM25, phrase/prefix matching, snippets and Unicode tokenization. Its BM25 sorts better results toward smaller values; `ORDER BY rank LIMIT ?` can avoid unnecessary ranking work. Prefix indexes trade storage for prefix speed. External-content tables require explicit consistency maintenance and an initial rebuild. FTS5's separate secure-delete option also matters for Forget. [SQLite FTS5](https://www.sqlite.org/fts5.html).

**Proposed pilot:** a small SQLite module with bound parameters, literal query escaping, a final-token prefix query, bounded top results, and explicit task/source filters. Preserve exact name/URL matches near the top. Test `unicode61` first; evaluate segmentation for CJK and mixed-script captures before claiming multilingual lexical quality. Avoid enabling English stemming for every language. Empty input should return a bounded recent list. Keep partially composed IME text intact while updating a query only when appropriate.

[GRDB](https://github.com/groue/GRDB.swift) is an MIT Swift SQLite toolkit worth comparing with a small direct SQLite adapter. Its existence does not establish compatibility with the project's compiler, extension target, encrypted database choice, or deployment versions. Pin and test the selected revision.

WAL permits readers alongside a writer, while retaining a single-writer constraint and extra WAL/shared-memory files. It is local concurrency, without a cross-device replication protocol. Current upstream docs identify a rare WAL-reset corruption bug fixed in 3.51.3 and later, with backports including 3.44.6 and 3.50.7. Verify the actual linked library and vendor patch status before enabling a shared app/extension WAL design. [SQLite WAL documentation](https://www.sqlite.org/wal.html).

## Semantic candidates

| Candidate | Verified upstream behavior | Product decision still needed |
| --- | --- | --- |
| Apple `NLEmbedding` sentence embeddings | Apple documents sentence similarity and paraphrase retrieval. A requested language/revision may be unavailable; APIs expose supported sentence revisions. [Similarity guide](https://developer.apple.com/documentation/naturallanguage/finding-similarities-between-pieces-of-text), [revision API](https://developer.apple.com/documentation/naturallanguage/nlembedding/sentenceembedding(for:revision:)). | Cheapest integration baseline because the app already calls it. Test language support, cold load, quality and keyboard memory on real devices. Persist model identity and revision. |
| Apple `NLContextualEmbedding` | Produces contextual vector sequences and requires available/downloaded assets. Apple specifically directs semantic similarity use toward `NLEmbedding`. [Apple documentation](https://developer.apple.com/documentation/naturallanguage/nlcontextualembedding). | It is not automatically a better sentence retriever. Pooling and retrieval training need evaluation before using it for this job. |
| `all-MiniLM-L6-v2` | Apache-2.0, English, 384 dimensions, default truncation at 256 word pieces. [Publisher model card](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2). | A compact comparison model; converted Core ML artifact, tokenizer, pooling, numerical parity, packaging and device memory remain unverified. |
| `multilingual-e5-small` | MIT, 384 dimensions, supports 100 languages with low-resource caveats; 512-token limit. Retrieval uses `query:`/`passage:` prefixes, mean pooling and normalization. [Publisher model card](https://huggingface.co/intfloat/multilingual-e5-small/raw/main/README.md). | Candidate for the founder's mixed-language corpus. Larger runtime/model cost and actual keyboard feasibility need measurement. |
| MLX embedding runtime | `MLXEmbedders` now lives in `mlx-swift-lm`; current main has breaking 3.x changes. [Current upstream](https://github.com/ml-explore/mlx-swift-lm), [migration notice](https://github.com/ml-explore/mlx-swift-examples). | Useful Mac/companion comparison. A framework supporting iOS does not establish keyboard-extension suitability. Pin a compatible version. |

[Apple coremltools](https://github.com/apple/coremltools) provides conversion and validation tooling. Model conversion success alone would leave tokenizer/pooling parity and retrieval quality to prove. Keep model libraries and weights behind an embedding adapter; do not expose a model name or server URL as the ordinary Find experience.

**Proposed indexing:** divide long captures into bounded overlapping paragraph/sentence chunks, retain exact original spans, and embed each chunk once per content/model/chunker revision. Deduplicate ranked chunks back to their original source. Index retained chat with role, timestamp and exchange attribution; exclude Temporary segments. No mandatory categories are required.

Start with normalized vectors and bounded exact similarity search over precomputed vectors; compare an Accelerate implementation with sqlite-vec rather than assuming an approximate index is needed. [Accelerate exposes vector dot products](https://developer.apple.com/documentation/accelerate/vdsp/dot(_:_:)-9uigz). [sqlite-vec](https://github.com/asg017/sqlite-vec) is dependency-free C, supports float/int8/binary vectors, and explicitly remains pre-v1. Its extension packaging, encrypted SQLite compatibility and memory profile remain untested here. Reconsider ANN only after exact search exceeds the device budget.

For perspective, 10,000 vectors × 384 dimensions × 4-byte floats occupy about 15.4 MB before IDs, metadata, chunks, model weights and framework overhead. At 100,000 vectors the same raw storage is about 154 MB. These are arithmetic estimates, not resident-memory measurements.

## Proposed module contract

One caller-facing retrieval boundary should serve the keyboard, Mac panel and remembered chat:

```text
apply(changes: upserts + tombstones, sourceGeneration) -> IndexReceipt
search(query, filters, limit, requestID) -> stream<SearchBatch>
original(sourceID) -> OriginalWithAttribution?
status() -> ready / catchingUp / lexicalOnly / unavailable
```

`SearchBatch` carries request ID, source generation, lexical/hybrid stage, ranked source references, matching spans and availability state. The interface hides SQLite, chunking, vector engine and model selection. Opening an original resolves the current source instead of trusting a cached snippet. A bounded result set is published once per stage and reused by list/empty-state rendering.

**Proposed consistency:** make saved source content and lexical indexing one transaction when persistence moves into SQLite. While JSON remains authoritative, use a durable revision/generation manifest, an idempotent change journal and recovery reconciliation; do not claim atomicity across JSON and SQLite. Read-after-save searches must include the just-saved source even when rebuilding. Compare source content hashes before applying delayed embedding work. Store model ID/revision/dimensions plus chunker version with vectors. Reject work for deleted or superseded sources. Rebuild derived indexes without rewriting originals.

**Proposed query scheduling:** run database and embedding work outside the main actor. Publish lexical candidates promptly, with a short separately tunable debounce for semantic work. Cancel obsolete work, and additionally check request ID plus corpus generation immediately before publication. Clearing the field cancels the prior request; it must not let old results replace recent items. Swift cancellation is cooperative, so calling cancel alone is insufficient. [Swift Task cancellation](https://docs.swift.org/latest/documentation/swift/task/cancel()/). SQLite offers connection-level interrupt and progress-handler cancellation; isolate reader work so cancelling Find cannot interrupt a capture write. [Interrupt](https://www.sqlite.org/c3ref/interrupt.html), [progress handler](https://www.sqlite.org/c3ref/progress_handler.html).

## Extension and privacy gates

Apple documents lower memory budgets for app extensions and discourages blocking the main run loop or putting resource-heavy work there. Its keyboard guide describes open-access requirements for shared storage/network access. Neither source supplies a universal numeric keyboard memory ceiling. [Extension efficiency](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html), [custom keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html).

**Proposed controls:** keep lexical capture/find usable offline and without a chat server. Provision large model assets through the companion; test a small query encoder inside the actual extension. Do not assume the companion can remain running as a local inference daemon. A lightweight lexical path remains useful while semantic assets are unavailable, but it must not be advertised as proven semantic quality.

Protect indexes, vectors, snippets and model-input logs as personal vault data. Treat derived stores and their journal files as part of the encryption/deletion boundary. Do not upload embeddings by default. Default FTS deletion can retain old terms; core `secure_delete` alone has virtual-table limitations. [SQLite secure-delete warning](https://www.sqlite.org/pragma.html#pragma_secure_delete). A tested Forget operation must prevent stale cache/task/query publication and delete the relevant derived records. Backup/WAL/SSD erasure guarantees require a separate security design. The accepted service-unreadable sync contract remains in [ADR 0001](../adr/0001-private-sync-and-optional-cloud-ai.md).

## Proposed acceptance budgets — all unmeasured

Measure Release builds on the oldest supported real iPhone and a named Mac, with 1k/10k/100k realistic mixed-length captures/chunks. Record device, OS, model/revision, database size, cold/warm state, thermal/power state, p50/p95/p99, and main-thread stalls. Simulator timings cannot establish phone performance.

| Measurement | Initial target to validate |
| --- | --- |
| Keyboard/Mac input responsiveness | No search-induced main-thread stall over one display frame; p95 input handling under 8 ms |
| Warm query to first visible lexical results, 10k captures | p95 under 50 ms; p99 under 100 ms, including chosen debounce and UI publication |
| Warm query to semantic-enriched results, 10k captures | p95 under 150 ms; p99 under 300 ms; report query encoding separately |
| Cold keyboard opening with first usable results | p95 under 300 ms; never wait for a model download |
| Durable save to lexical search visibility | Same-process read-after-save immediately; cross-process refresh p95 under 100 ms while active |
| New-source semantic availability | p95 under 2 s for a short capture while execution is available; show deferred state after extension suspension |
| Rapid typing, deletion and filter changes | Zero stale-query result publications across at least 1,000 generated interleavings |
| Forget/edit during indexing/search | Zero deleted or superseded snippets, results or late vector writes |
| Retrieval quality | Start with at least 100 held-out founder-approved queries; known exact identifiers recall@5 at least 99%, paraphrase recall@5 at least 90%; inspect failures and confidence intervals |

Include misspellings, name fragments, synonyms without word overlap, mixed English/Hindi and transliteration if used, short unfinished queries, long essays with an important detail near the end, multiple similar captures, no-answer queries, and chat attribution. Compare lexical-only, current embeddings, MiniLM and E5 against the same judgments. Thresholds are starting proposals; no chosen model has passed them. Do not optimize only the easy synthetic corpus. Measure memory/energy and extension termination; set an operating margin from real-device observations rather than inventing an OS memory limit.

## Rust decision

Keep the first index adapter in Swift around SQLite and the platform embedding boundary. SQLite already executes its engine in C. Removing repeated document embedding, full-corpus JSON reads, unbounded sorting and main-thread work should precede a language migration. This is an engineering recommendation from source inspection, without a comparative benchmark.

Choose a Rust implementation only if profiling isolates a material compute bottleneck or a shared non-Apple core justifies its added FFI, ownership/cancellation, packaging and audit cost. Preserve the same contract and benchmark an interchangeable engine. Rust does not itself make remote sync low-latency or make semantic retrieval accurate. The separate client survey evaluates the user-supplied Rustcast project.

No implementation, ticket status, privacy protocol or model selection was changed by this research note.
