/* Release benchmark at the saved-vault seam. macOS CI reports 10k-note query
 p95, durable save p95, database bytes and whole-process peak resident memory. */
import XCTest
import Darwin
import MindMachineCore

final class SearchPerformanceTests: XCTestCase {
    func testTenThousandNotesQueryBudget() throws {
        #if DEBUG
        throw XCTSkip("Run with swift test -c release for the performance budget")
        #else
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = VaultFile(url: folder.appendingPathComponent("vault.json"))
        let nouns = ["telescope", "birthday", "passport", "recipe", "meeting", "garden", "invoice", "holiday", "bicycle", "library"]
        try store.update { vault in
            for i in 0..<10_000 {
                vault.captures.append(Capture(text: "\(nouns[i % 10]) project \(i) remember the original plan for Mira with reference code item\(i) and a useful link https://example.com/\(i)"))
            }
        }
        let queries = ["", "p", "pr", "teles", "telescpoe", "passport", "birthd", "gardne", "item9876", "recipe project", "nohitsxyz"]
        XCTAssertEqual(try store.search("item9876").first?.capture.text.contains("reference code item9876"), true)
        XCTAssertFalse(try store.search("telescpoe").isEmpty)
        XCTAssertEqual(try store.search("pr").first?.capture.text.contains("project 9999"), true)
        for query in queries { _ = try store.search(query) }
        var timings: [Double] = []
        var perQuery: [String: [Double]] = [:]
        for i in 0..<240 {
            let start = DispatchTime.now().uptimeNanoseconds
            _ = try store.search(queries[i % queries.count])
            let ms = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
            timings.append(ms)
            perQuery[queries[i % queries.count], default: []].append(ms)
        }
        var saves: [Double] = []
        for i in 0..<30 {
            let start = DispatchTime.now().uptimeNanoseconds
            try store.append(Capture(text: "Fresh capture \(i)"))
            saves.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
        }
        for query in queries { let samples = perQuery[query]!.sorted(); print("MM_QUERY \(query) p95_ms=\(samples[Int(Double(samples.count)*0.95)-1])") }
        let p95 = timings.sorted()[Int(Double(timings.count) * 0.95)-1]
        let saveP95 = saves.sorted()[Int(Double(saves.count) * 0.95)-1]
        var usage = rusage(); getrusage(RUSAGE_SELF, &usage)
        print("MM_BENCH notes=10000 queries=240 query_p95_ms=\(p95) save_p95_ms=\(saveP95) peak_rss_mib=\(Double(usage.ru_maxrss)/1048576)")
        XCTAssertLessThan(p95, 10, "Warm ranked prefix/typo search p95 must stay under 10 ms")
        #endif
    }
}
