/* Compares benchmark observations with the committed main baseline. Called only
 by SearchPerformanceTests, VaultIntegrityProbe and the Mac PillSelfTest gates;
 normal Capture/Recall operations do not invoke performance checks. */
import Foundation

public enum PerformanceRatchet {
    struct Metric {
        let main: Double
        let absoluteMargin: Double
        var ceiling: Double { main * 1.25 + absoluteMargin }
    }

    public struct Failure: Error, CustomStringConvertible {
        public let description: String
    }

    /// Every expected measurement must exist and be finite and positive. Extra
    /// observations fail too, so adding a metric requires an explicit baseline.
    /// Diagnostics name the main value and both allowances; no retry hides tails.
    public static func check(_ group: String, measurements: [String: Double]) throws {
        guard let metrics = baseline[group], Set(metrics.keys) == Set(measurements.keys) else {
            throw Failure(description: "MM_RATCHET FAIL \(group): measurements must exactly match baseline metrics")
        }
        var failures: [String] = []
        for name in metrics.keys.sorted() {
            let metric = metrics[name]!
            let measured = measurements[name]!
            let passed = measured.isFinite && measured > 0 && measured <= metric.ceiling
            let line = "MM_RATCHET \(passed ? "PASS" : "FAIL") \(group).\(name) measured=\(measured) main=\(metric.main) relative=0.25 absolute=\(metric.absoluteMargin) ceiling=\(metric.ceiling)"
            print(line)
            if !passed { failures.append(line) }
        }
        if !failures.isEmpty { throw Failure(description: failures.joined(separator: "\n")) }
    }

    /// core-checks already takes three independent fresh processes. Keep its
    /// median of per-process values (append values are each 100-save p95s).
    /// Require all three complete records before computing any comparison.
    public static func checkKeyboardLog(_ text: String) throws {
        let prefix = "MM_KEYBOARD_CORE "
        let records = try text.components(separatedBy: .newlines).filter { $0.hasPrefix(prefix) }.map {
            try JSONSerialization.jsonObject(with: Data($0.dropFirst(prefix.count).utf8)) as? [String: Double]
        }
        guard records.count == 3 else {
            throw Failure(description: "MM_RATCHET FAIL keyboard: expected three fresh-process records")
        }
        var medians: [String: Double] = [:]
        for name in baseline["keyboard"]!.keys {
            let values = records.compactMap { $0?[name] }
            guard values.count == 3, values.allSatisfy({ $0.isFinite && $0 > 0 }) else {
                throw Failure(description: "MM_RATCHET FAIL keyboard.\(name): expected three positive finite values")
            }
            medians[name] = values.sorted()[1]
        }
        try check("keyboard", measurements: medians)
    }
}
