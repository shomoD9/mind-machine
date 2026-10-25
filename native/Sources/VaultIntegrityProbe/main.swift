/* Process-level durability/resource probe called by verify_vault_processes.py,
 checks.sh and native-ci. stdout acknowledges only completed saves; SIGKILL
 exercises recovery. ratchet-keyboard compares checks.sh's three fresh samples. */
import Foundation
import Darwin
import MindMachineCore

let args = CommandLine.arguments
if args.count < 3 { fatalError("usage: VaultIntegrityProbe write|read vault.json [prefix] [count]") }
let store = VaultFile(url: URL(fileURLWithPath: args[2]))
do {
    if args[1] == "ratchet-keyboard" {
        // Read the existing benchmark output after its fixed-budget checks.
        try PerformanceRatchet.checkKeyboardLog(String(contentsOfFile: args[2], encoding: .utf8))
    } else if args[1] == "write" {
        let prefix = args[3], count = Int(args[4])!
        for i in 0..<count {
            let text = "\(prefix)-\(i)"
            try store.append(Capture(text: text))
            FileHandle.standardOutput.write(Data((text + "\n").utf8))
        }
    } else if args[1] == "seed" {
        let nouns = ["telescope", "birthday", "passport", "recipe", "meeting", "garden", "invoice", "holiday", "bicycle", "library"]
        try store.update { vault in
            for i in 0..<10_000 {
                vault.captures.append(Capture(text: "\(nouns[i % 10]) project \(i) remember the original plan for Mira with reference code item\(i) and a useful link https://example.com/\(i)", createdAt: Date(timeIntervalSince1970: Double(i))))
            }
        }
    } else if args[1] == "benchmark-keyboard" {
        // Fresh process, existing 10k vault: measure the bounded snapshot and
        // first Recall separately from fixture creation and steady-state saves.
        let opened = DispatchTime.now().uptimeNanoseconds
        let snapshot = try store.read(captureLimit: 100)
        let openMS = Double(DispatchTime.now().uptimeNanoseconds-opened)/1_000_000
        guard snapshot.captures.count == 100 else { fatalError("Expected the keyboard's hundred-source window") }
        let queried = DispatchTime.now().uptimeNanoseconds
        let hits = try store.search("teles")
        let firstMS = Double(DispatchTime.now().uptimeNanoseconds-queried)/1_000_000
        guard hits.count == 30 else { fatalError("Expected thirty Recall originals") }
        var saves: [Double] = []
        for index in 0..<100 {
            let start = DispatchTime.now().uptimeNanoseconds
            try store.append(Capture(text: "Durable keyboard capture \(index)"))
            saves.append(Double(DispatchTime.now().uptimeNanoseconds-start)/1_000_000)
        }
        var usage = rusage(); getrusage(RUSAGE_SELF,&usage)
        let metrics: [String: Double] = ["cold_snapshot_ms": openMS, "first_recall_ms": firstMS,
            "append_p95_ms": saves.sorted()[94], "peak_rss_mib": Double(usage.ru_maxrss)/1048576,
            "footprint_mib": ProcessMemory.sample()?.footprintMiB ?? -1]
        let json = try JSONSerialization.data(withJSONObject: metrics, options: [.sortedKeys])
        print("MM_KEYBOARD_CORE " + String(decoding: json, as: UTF8.self))
    } else if args[1] == "benchmark" {
        let queries = ["", "p", "pr", "teles", "telescpoe", "passport", "birthd", "gardne", "item9876", "recipe project", "nohitsxyz"]
        let start = DispatchTime.now().uptimeNanoseconds
        _ = try store.search("teles")
        let cold = Double(DispatchTime.now().uptimeNanoseconds-start)/1_000_000
        var timings: [Double] = []
        for query in queries { _ = try store.search(query) }
        for i in 0..<240 {
            let begin = DispatchTime.now().uptimeNanoseconds
            _ = try store.search(queries[i % queries.count])
            timings.append(Double(DispatchTime.now().uptimeNanoseconds-begin)/1_000_000)
        }
        var usage = rusage(); getrusage(RUSAGE_SELF,&usage)
        print("MM_FTS5 notes=10000 query_p95_ms=\(timings.sorted()[227]) cold_open_and_first_query_ms=\(cold) peak_rss_mib=\(Double(usage.ru_maxrss)/1048576) footprint_mib=\(ProcessMemory.sample()?.footprintMiB ?? -1)")
    } else {
        let vault = try store.read()
        let data = try JSONEncoder().encode(vault.captures.map(\.text))
        FileHandle.standardOutput.write(data)
        if let sample = ProcessMemory.sample() {
            FileHandle.standardError.write(Data("MM_STORE footprint_mib=\(sample.footprintMiB)\n".utf8))
        }
    }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
