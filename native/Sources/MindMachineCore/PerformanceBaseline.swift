/* Hosted-main measurements and absolute noise allowances used exclusively by
 PerformanceRatchet's existing CI gate callers. Units are ms except peak RSS
 (MiB). Provenance and intentional refresh procedure: docs/verification/performance-ratchet.md. */
extension PerformanceRatchet {
    // main e556df507da4902afdb58e6953a974dc0980b650, Xcode 26.2/macOS 26.
    // native-ci 40216843098: search-benchmark.txt and pill-selftest/result.json.
    // core-checks 40216843122: medians of three MM_KEYBOARD_CORE records.
    // Each limit adds 25% plus its absolute allowance to the measured main value.
    static let baseline: [String: [String: Metric]] = [
        "search": [
            "query_p95_ms": Metric(main: 3.839875, absoluteMargin: 0.75),
            "save_p95_ms": Metric(main: 3.142959, absoluteMargin: 2),
            "query:": Metric(main: 0.206416, absoluteMargin: 0.5),
            "query:p": Metric(main: 4.045375, absoluteMargin: 1.5),
            "query:pr": Metric(main: 2.20725, absoluteMargin: 1),
            "query:teles": Metric(main: 1.681542, absoluteMargin: 1),
            "query:telescpoe": Metric(main: 1.653167, absoluteMargin: 1),
            "query:passport": Metric(main: 1.605167, absoluteMargin: 1),
            "query:birthd": Metric(main: 1.6775, absoluteMargin: 1),
            "query:gardne": Metric(main: 1.645917, absoluteMargin: 1),
            "query:item9876": Metric(main: 0.191583, absoluteMargin: 0.5),
            "query:recipe project": Metric(main: 2.362166, absoluteMargin: 1),
            "query:nohitsxyz": Metric(main: 0.2205, absoluteMargin: 0.5),
        ],
        "keyboard": [
            "cold_snapshot_ms": Metric(main: 8.16375, absoluteMargin: 3),
            "first_recall_ms": Metric(main: 4.006375, absoluteMargin: 2),
            "append_p95_ms": Metric(main: 3.3215, absoluteMargin: 2),
            "peak_rss_mib": Metric(main: 10.53125, absoluteMargin: 1),
        ],
        "recallTyping": [
            "dispatch_p95_ms": Metric(main: 6.434666666677913, absoluteMargin: 2),
            "letter_p95_ms": Metric(main: 32.38804166667819, absoluteMargin: 5),
            "cards_p95_ms": Metric(main: 70.70345833332681, absoluteMargin: 10),
        ],
    ]
}
