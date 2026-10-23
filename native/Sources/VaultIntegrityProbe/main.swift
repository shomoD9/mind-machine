/* Process-level durability probe called by Scripts/verify_vault_processes.py in
 macOS CI. stdout acknowledges only completed saves; SIGKILL exercises recovery. */
import Foundation
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
