/* Portable tests of the actual comparator used by Release tests, the keyboard
 process gate and Mac self-test. fast-core runs these without timing Linux. */
import XCTest
@testable import MindMachineCore

final class PerformanceRatchetTests: XCTestCase {
    private func mainValues(_ group: String) -> [String: Double] {
        PerformanceRatchet.baseline[group]!.mapValues(\.main)
    }

    func testMainAndNoiseBoundaryPassForEveryMetric() throws {
        for (group, metrics) in PerformanceRatchet.baseline {
            try PerformanceRatchet.check(group, measurements: mainValues(group))
            try PerformanceRatchet.check(group, measurements: metrics.mapValues(\.ceiling))
        }
    }

    func testEveryMetricRejectsAnIndependentRegression() {
        for (group, metrics) in PerformanceRatchet.baseline {
            for (name, metric) in metrics {
                var values = mainValues(group)
                values[name] = metric.ceiling + 0.001
                XCTAssertThrowsError(try PerformanceRatchet.check(group, measurements: values)) { error in
                    XCTAssertTrue(String(describing: error).contains("FAIL \(group).\(name) measured="))
                }
            }
        }
    }

    func testDeliberateSlowdownFailsBelowOldFixedBudgets() {
        // 6 ms Recall and 7 ms saves pass the old 10/12 ms caps. The real
        // gate must reject each against main, even with the noise allowance.
        for (name, slower, fixed) in [("query_p95_ms", 6.0, 10.0), ("save_p95_ms", 7.0, 12.0)] {
            XCTAssertLessThan(slower, fixed)
            var values = mainValues("search")
            values[name] = slower
            XCTAssertThrowsError(try PerformanceRatchet.check("search", measurements: values)) { error in
                XCTAssertTrue(String(describing: error).contains("FAIL search.\(name) measured=\(slower)"))
            }
        }
    }

    func testMissingExtraAndInvalidMeasurementsFailClosed() {
        XCTAssertThrowsError(try PerformanceRatchet.check("unknown", measurements: [:]))
        var values = mainValues("search")
        values.removeValue(forKey: "query_p95_ms")
        XCTAssertThrowsError(try PerformanceRatchet.check("search", measurements: values))
        values = mainValues("search")
        values["newMetric"] = 1
        XCTAssertThrowsError(try PerformanceRatchet.check("search", measurements: values))
        for invalid in [Double.nan, .infinity, -.infinity, 0, -1] {
            values = mainValues("search")
            values["query_p95_ms"] = invalid
            XCTAssertThrowsError(try PerformanceRatchet.check("search", measurements: values))
        }
    }

    private func keyboardLog(_ samples: [[String: Double]]) throws -> String {
        try samples.map { "MM_KEYBOARD_CORE " + String(decoding: try JSONSerialization.data(withJSONObject: $0), as: UTF8.self) }.joined(separator: "\n")
    }

    func testKeyboardUsesThreeCompleteSamplesAndMedian() throws {
        let normal = mainValues("keyboard")
        let slow = normal.mapValues { $0 * 10 }
        try PerformanceRatchet.checkKeyboardLog(keyboardLog([normal, slow, normal]))
        XCTAssertThrowsError(try PerformanceRatchet.checkKeyboardLog(keyboardLog([normal, slow, slow])))
        XCTAssertThrowsError(try PerformanceRatchet.checkKeyboardLog(keyboardLog([normal, normal])))
        XCTAssertThrowsError(try PerformanceRatchet.checkKeyboardLog(keyboardLog([normal, normal, [:]])))
        XCTAssertThrowsError(try PerformanceRatchet.checkKeyboardLog("MM_KEYBOARD_CORE malformed"))
        var invalid = normal
        invalid["peak_rss_mib"] = -1
        XCTAssertThrowsError(try PerformanceRatchet.checkKeyboardLog(keyboardLog([normal, normal, invalid])))
    }
}
