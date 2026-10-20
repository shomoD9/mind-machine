/* Resolves device-local shared storage for the companion and keyboard targets.
 Both apps call this before constructing VaultModel; Mac uses its own sandbox. */
import Foundation

struct DeviceVault {
    // A missing entitled group is an installation error. The keyboard must not
    // silently create an isolated vault that looks as though the companion shares it.
    static func sharedURL() throws -> URL {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "VaultAppGroup") as? String,
              !group.isEmpty,
              let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { throw StorageError.sharedContainerUnavailable }
        return directory.appendingPathComponent("SecondBrain/vault.json")
    }

    enum StorageError: LocalizedError {
        case sharedContainerUnavailable
        var errorDescription: String? {
            "Shared vault unavailable. Configure the same signed App Group for the app and keyboard, then enable Full Access for the keyboard."
        }
    }
}
