# MiniSearch native feasibility probe

MiniSearch 7.1.0 ran inside Apple's JavaScriptCore from a compiled Swift executable. The 10,000-document timed run returned the expected exact, prefix, typo and Hindi literal matches, reloaded its serialized index and excluded a discarded document. This establishes a native integration path for these operations. It does not establish keyboard-extension feasibility or semantic search quality.

## Reproduction and provenance

- Harness: [MiniSearchProbe.swift](../../native/Benchmarks/MiniSearchProbe.swift). No production target imports it. It uses generated fixtures and never opens the personal vault or calls an inference endpoint.
- Version 7.1.0 matches [Omnisearch's inspected package manifest](https://github.com/scambier/obsidian-omnisearch/blob/0a4e93b2ed155b84c3fe89f6d2d19c5a8c171a87/package.json). This pins the experiment; it is not a claim that 7.1.0 is upstream's newest release.
- Downloaded from the [official npm version metadata](https://registry.npmjs.org/minisearch/7.1.0). Verified the tarball against published SHA-512 integrity before extracting only `dist/umd/index.js`, `LICENSE.txt` and `package.json`. No dependency installation or package scripts ran.
- Published integrity: `sha512-tv7c/uefWdEhcu6hvrfTihflgeEi2tN6VV7HJnCjK6VxM75QQJh4t9FwJCsA2EsRS8LCnu3W87CuGPWMocOLCA==`.
- UMD file: 88,694 bytes; SHA-256 `bd47ccf2b0028aaee23a301b018f238e0e511b6e8439fd9cdaf8e4242c46e149`. Temporary path `/tmp/secondbrain-minisearch-7.1.0/index.js`; not vendored into the app/repository. Retain the upstream MIT and bundled helper notices if subsequently shipped.
- Host: arm64 macOS 15.7.3, Swift 6.2.3, Xcode 26.2. Optimized standalone executable. CPU model was not recorded.

```sh
swiftc -O -module-cache-path /tmp/secondbrain-search-probe-module-cache \
  native/Benchmarks/MiniSearchProbe.swift -parse-as-library \
  -framework JavaScriptCore -o /tmp/secondbrain-minisearch-probe
/tmp/secondbrain-minisearch-probe /tmp/secondbrain-minisearch-7.1.0/index.js 1000
/usr/bin/time -l /tmp/secondbrain-minisearch-probe /tmp/secondbrain-minisearch-7.1.0/index.js 10000
```

The time utility's resource counters required unsandboxed execution on this host. An earlier sandboxed invocation printed successful harness output but the utility exited unsuccessfully; resource numbers below come from the subsequent successful timed run.

## Corpus and measurement

The synthetic corpus repeats five short topic templates with unique titles, plus two known-match documents. It has little vocabulary diversity and no essays, attachments or retained chat. Configured fields are title/text, title boost 2, prefix enabled, fuzzy 0.2 and AND combination. Each query has 50 sequential samples; p50/p95 use sorted sample positions 25/48. The first call is included, though later samples reuse a warm runtime/index. Durations include the Swift-to-JavaScript call and conversion of ten returned IDs. The library may rank more candidates internally.

### Successful timed 10,000-document run

| Query | Purpose | p50 ms | p95 ms | Maximum ms | Result |
| --- | --- | ---: | ---: | ---: | --- |
| birthday | Literal title | 0.812 | 1.500 | 5.453 | ID 42 first |
| birthd | Prefix | 0.108 | 0.120 | 0.421 | ID 42 first |
| bithday | Typo | 0.105 | 0.122 | 0.130 | ID 42 first |
| चाय | Hindi literal | 0.109 | 0.125 | 0.397 | ID 43 first |
| maternal celebration | No-overlap paraphrase | 1.623 | 2.232 | 2.748 | Empty, as expected for this lexical fixture |
| train | Common term, many matches | 1.997 | 3.807 | 7.368 | Ten IDs returned |

Runtime/bundle startup: 71.878 ms. Index construction including fixture creation: 354.991 ms. Serialized index: 1,631,025 bytes. Serialization/reload and discard checks passed. Whole command: 0.90 seconds wall time. Maximum resident set size: 99,483,648 bytes (94.9 MiB); reported peak footprint: 64,882,112 bytes (61.9 MiB).

**These memory figures cover the entire process**, including synthetic documents, runtime, serialized strings, original and reloaded indexes. They do not isolate index overhead and do not predict an iPhone keyboard's allowed memory. They make a device-memory check necessary before adoption.

An earlier untimed 10k run had startup 59.480 ms, construction 363.664 ms, and query p95 0.118–4.012 ms. The 1k run had startup 80.102 ms, construction 46.028 ms and query p95 0.127–2.198 ms. These are small characterization runs, without device-level confidence intervals.

## Interpretation and remaining checks

The tested synchronous library path needs neither Obsidian nor a browser/WebView. JavaScriptCore successfully ran the UMD bundle. Async/timer-dependent operations were not exercised. A passing literal Hindi query does not prove language segmentation, transliteration or multilingual semantic quality.

Before choosing this adapter, compare it with SQLite FTS5 on the same realistic corpus and public retrieval seam. Measure extension cold activation, memory, edits/deletions, cross-process freshness, full query-to-visible-results latency, typing responsiveness and mixed-language relevance on real devices. Test protected index persistence and crash/rebuild recovery. Generate embeddings separately, once per content/model revision, and evaluate paraphrases against judged queries.

Do not claim a speedup ratio against the [existing retrieval baseline](search-baseline-2026-10-22.md): that path computes semantic embeddings on a different corpus. No production retrieval logic or dependencies changed in this experiment.
