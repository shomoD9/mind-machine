/* Process-level durability probe called by Scripts/verify_vault_processes.py in
 macOS CI. stdout acknowledges only completed saves; SIGKILL exercises recovery. */
import Foundation
import Darwin
import MindMachineCore

let args = CommandLine.arguments
if args.count < 3 { fatalError("usage: VaultIntegrityProbe write|read vault.json [prefix] [count]") }
let store = VaultFile(url: URL(fileURLWithPath: args[2]))
do {
    if args[1] == "write" {
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
                vault.captures.append(Capture(text: "\(nouns[i % 10]) project \(i) remember the original plan for Mira with reference code item\(i) and a useful link https://example.com/\(i)"))
            }
        }
    } else if args[1] == "benchmark" {
        let queries = ["teles", "telescpoe", "passport", "birthd", "gardne", "item9876", "recipe project", "nohitsxyz"]
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
