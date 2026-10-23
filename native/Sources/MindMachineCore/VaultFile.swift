// Coordinated atomic local persistence shared by companion and keyboard processes.
// Native app targets provide either their sandbox URL or an entitled App Group URL.
import Foundation

public final class VaultFile {
    public let url: URL

    public init(url: URL) { self.url = url }

    /// Missing storage represents a new local vault; corrupted storage raises an
    /// error. Replacing corruption with an empty document would silently lose data.
    public func read() throws -> Vault {
        guard FileManager.default.fileExists(atPath: url.path) else { return Vault() }
        return try JSONDecoder().decode(Vault.self, from: Data(contentsOf: url))
    }

    /// Read the newest file inside the coordinated writer closure so a keyboard
    /// capture does not overwrite a newer companion-app capture from stale memory.
    @discardableResult
    public func update(_ mutate: (inout Vault) throws -> Void) throws -> Vault {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var coordinationError: NSError?
        var outcome: Result<Vault, Error>?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forMerging, error: &coordinationError) { coordinatedURL in
            outcome = Result {
                var current = try read()
                try mutate(&current)
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                try encoder.encode(current).write(to: coordinatedURL, options: .atomic)
                return current
            }
        }
        if let coordinationError { throw coordinationError }
        guard let outcome else { throw CocoaError(.fileWriteUnknown) }
        return try outcome.get()
    }
}
