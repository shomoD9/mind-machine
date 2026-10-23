/* Shared-key Keychain adapter used by companion setup and VaultModel. The group
 entitlement lets the phone app/keyboard share the same explicitly paired key;
 iCloud Keychain can deliver it to the signed Mac under the same team. */
import Foundation
import Security
import CryptoKit

public enum PrivateSyncKey {
    public static let service = "com.getstatemachine.mindmachine.private-sync.v1"
    private static func query(group: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: "vault-key",
         kSecAttrAccessGroup as String: group, kSecAttrSynchronizable as String: true]
    }
    public static func load(group: String) throws -> Data? {
        var request = query(group: group)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let code = SecItemCopyMatching(request as CFDictionary, &result)
        if code == errSecItemNotFound { return nil }
        guard code == errSecSuccess else { throw keyError(code) }
        guard let data = result as? Data, data.count == 32 else { throw SyncFailure.invalidKey }
        return data
    }
    /// Never auto-generate on launch: two offline devices must not invent two
    /// unrelated keys. Creation/pairing is an explicit founder setup operation.
    public static func install(_ data: Data, group: String) throws {
        guard data.count == 32 else { throw SyncFailure.invalidKey }
        if let current = try load(group: group) {
            guard current == data else { throw SyncFailure.invalidKey }; return
        }
        var request = query(group: group)
        request[kSecValueData as String] = data
        request[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let code = SecItemAdd(request as CFDictionary,nil)
        if code == errSecDuplicateItem {
            guard try load(group: group) == data else { throw SyncFailure.invalidKey }; return
        }
        guard code == errSecSuccess else { throw keyError(code) }
    }
    public static func create() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }
    private static func keyError(_ code: OSStatus) -> NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(code), userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(code,nil) as String? ?? "Keychain unavailable"])
    }
}
