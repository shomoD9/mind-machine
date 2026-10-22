# Search baseline — 22 October 2026

Current source: `5ebb61be52a403942c1933843a9a06e4e52df3c7`. One-off characterization through the production `VaultFile` / `VaultModel.results` public interface, with synthetic notes only and OS notifications disabled. No personal vault or network inference endpoint was used. macOS 15.7.3, arm64; CPU model query was restricted in this environment and is not inferred. This is a development-host baseline, not an iPhone or consumer latency result.

## Observations

| Build / captures | birthday | gift for mother | travel packing |
| --- | ---: | ---: | ---: |
| Debug / 100 | 955 ms | 1,043 ms | 955 ms |
| Release / 100 | 866 ms | 815 ms | 885 ms |
| Release / 1,000 | 8,943 ms | 8,984 ms | 8,705 ms |

Every fixture has the same short note body with an index prefix. These three timings per corpus establish neither percentiles nor realistic relevance. The first two queries returned the full corpus; the third returned no result despite the fixture mentioning a train journey and packing a notebook. This is a diagnostic example, not a semantic-quality benchmark. Fixture construction and model creation are excluded from query timings. The first query can include cold embedding work; later queries still recompute every note's embedding.

The current interface runs on the main actor, repeats document embedding per query, then filters and sorts all captures. Native rendering can call it twice for the same query. The keyboard also needs explicit per-edit result publication. Changing programming language alone does not remove this work.

## Reproduce

The preserved [probe](../../native/Benchmarks/SearchBaseline.swift) calls the same public interface as Find, uses temporary coordinated storage and deletes that fixture after execution. Build the package first, then link the probe to those package objects:

```sh
swift build --package-path native --scratch-path /tmp/secondbrain-swift-release -c release
swiftc -O -module-cache-path /tmp/secondbrain-search-probe-module-cache -parse-as-library native/Benchmarks/SearchBaseline.swift -I /tmp/secondbrain-swift-release/arm64-apple-macosx/release/Modules /tmp/secondbrain-swift-release/arm64-apple-macosx/release/SecondBrainCore.build/*.swift.o /tmp/secondbrain-swift-release/arm64-apple-macosx/release/SecondBrainUI.build/*.swift.o -o /tmp/secondbrain-search-baseline-release
SEARCH_BENCHMARK_BUILD=Release /tmp/secondbrain-search-baseline-release 100
SEARCH_BENCHMARK_BUILD=Release /tmp/secondbrain-search-baseline-release 1000
```

The first compilation needed an explicit temporary module cache. Sandbox restrictions prevented NSFileCoordinator from saving even the temporary fixture; the authorized unsandboxed run succeeded. Those setup failures are separate from the query timing results.

## Next acceptance evidence

The [proposed plan](../../.scratch/native-mvp/plans/consumer-backend-2026-10-22.md) sets unmeasured initial latency budgets. Replace this synchronous path with transactional lexical indexing, revisioned precomputed vectors and asynchronous bounded result publication. Measure the actual UI path in Release on named real devices at 1k/10k/100k mixed-length captures, plus held-out judged retrieval queries. Report cold/warm p50/p95/p99, input stalls, memory and energy before claiming a speed or quality target is met.
