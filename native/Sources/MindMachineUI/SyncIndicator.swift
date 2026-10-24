/* Decides how much of the private-sync status the shared workspace footer shows. WorkspaceView
 (WorkspaceView.swift) builds one from VaultModel.syncStatus on every render and draws a small glyph that
 opens the sync setup sheet; WorkspaceTests checks the mapping for every status string VaultModel and
 PrivateCloudSync (MindMachineCore/PrivateCloudSync.swift) can produce. The sync code is untouched: this
 only reads its wording.

 Healthy states (syncing, up to date, a save waiting for the next exchange) show the glyph alone, so the
 footer does not flicker "Syncing privately…" every 15 seconds. An unpaired vault says "Sync off". Every
 other status is shown in full, so a new or unexpected error is visible by default rather than hidden. */
import Foundation

public struct SyncIndicator: Equatable, Sendable {
    public enum Level: Equatable, Sendable {
        /// No private key is paired; notes stay on this device.
        case off
        /// Sync is working or about to run; nothing for the person to do.
        case quiet
        /// Sync is waiting, paused or failed; the person may need to act.
        case attention
    }

    public let level: Level
    /// Words shown beside the glyph, or nil when the glyph is enough.
    public let label: String?
    /// SF Symbol name for the glyph.
    public let symbol: String
    /// The full status, used for the tooltip, accessibility value and the setup sheet.
    public let detail: String

    // Exact wording of the healthy states in VaultModel.syncNow/saveCapture and PrivateCloudSync.status.
    private static let healthy: Set<String> = [
        "Syncing privately…",
        "Private sync up to date",
        "Private sync ready",
        "Saved locally · sync pending",
    ]
    private static let unpairedPrefix = "Local vault · pair private sync"

    public init(status: String) {
        detail = status
        if status.hasPrefix(Self.unpairedPrefix) {
            level = .off; label = "Sync off"; symbol = "icloud.slash"
        } else if Self.healthy.contains(status) {
            level = .quiet; label = nil; symbol = "icloud"
        } else {
            level = .attention; label = status; symbol = "exclamationmark.icloud"
        }
    }
}
