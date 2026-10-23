/* One-off public-interface latency probe for the current saved-vault retrieval.
 Run by Codex during the 22 October backend plan; uses synthetic notes only,
 real VaultFile persistence and VaultModel.results, with OS notifications disabled. */
import Foundation
import MindMachineCore
import MindMachineUI

@main struct SearchBaseline {
    @MainActor static func main() throws {
        // Fixture setup is excluded from query timings and never opens the user's vault.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let file = VaultFile(url: url)
        // Scale only the synthetic corpus; timings still cross the production interface.
        let count = Int(CommandLine.arguments.dropFirst().first ?? "100") ?? 100
        let build = ProcessInfo.processInfo.environment["SEARCH_BENCHMARK_BUILD"] ?? "unspecified"
        _ = try file.update { vault in
            for index in 0..<count {
                vault.captures.append(Capture(text: "Note \(index): Buy a birthday present for mum. Save the shelf design link and pack a notebook for the train journey."))
            }
        }
        let model = VaultModel(url: url, notificationAccess: .disabled)
        print("mode=\(model.searchDescription), notes=\(count), build=\(build), corpus=synthetic")
        // Each call crosses the same public interface used by the native Recall UI.
        for query in ["birthday", "gift for mother", "travel packing"] {
            model.query = query
            let start = ContinuousClock.now
            let results = model.results()
            let elapsed = start.duration(to: .now)
            print("query=\(query), elapsed=\(elapsed), count=\(results.count)")
        }
    }
}
