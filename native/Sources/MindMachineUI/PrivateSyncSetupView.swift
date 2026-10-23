/* Explicit private-key pairing UI reused by iPhone setup and shared workspace
 settings. Creating a key is deliberate; sync never creates unrelated device keys. */
import SwiftUI
import MindMachineCore

public struct PrivateSyncSetupView: View {
    @State private var enteredKey = ""
    @State private var recoveryKey = ""
    @State private var status = ""
    @State private var paired = false
    public init() {}
    private var group: String? { Bundle.main.object(forInfoDictionaryKey: "VaultKeychainGroup") as? String }
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Private device sync").font(.headline)
            Text("Use the same iCloud account on iPhone and Mac. Create a key on one device only. On the second device, wait for iCloud Keychain or paste that key here. Keep a recovery copy: losing every copy makes cloud notes unreadable.")
                .font(.caption).foregroundStyle(.secondary)
            if paired {
                Text("Private key paired. Sync runs while Mind Machine or its keyboard is active.").font(.caption)
                Button("Show recovery key") { perform { recoveryKey = try existingKey().base64EncodedString() } }
            } else {
                SecureField("Private sync key from your first device", text: $enteredKey)
                    .textFieldStyle(.roundedBorder).autocorrectionDisabled()
                Button("Pair this device") {
                    perform {
                        guard let data = Data(base64Encoded: enteredKey.trimmingCharacters(in: .whitespacesAndNewlines)) else { throw SyncFailure.invalidKey }
                        try install(data); enteredKey = ""
                    }
                }.disabled(enteredKey.isEmpty)
                Button("Create key on my first device") {
                    perform { let data = PrivateSyncKey.create(); try install(data); recoveryKey = data.base64EncodedString() }
                }
            }
            if !recoveryKey.isEmpty {
                Text("Recovery key — keep private").font(.caption.bold())
                Text(recoveryKey).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                Button("Hide recovery key") { recoveryKey = "" }
            }
            if !status.isEmpty { Text(status).font(.caption) }
            Text("Local notes remain available offline. An iCloud account change pauses sync and keeps this vault on the device.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task { perform { paired = try group.flatMap { try PrivateSyncKey.load(group: $0) } != nil } }
    }
    private func existingKey() throws -> Data {
        guard let group, let key = try PrivateSyncKey.load(group: group) else { throw SyncFailure.missingKey }
        return key
    }
    private func install(_ data: Data) throws {
        guard let group else { throw SyncFailure.unavailable }
        try PrivateSyncKey.install(data, group: group); paired = true
        status = "Paired. Open Capture or Find to begin sync."
    }
    private func perform(_ work: () throws -> Void) {
        do { try work() } catch { status = error.localizedDescription }
    }
}
