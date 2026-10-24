// swift-tools-version: 5.9
/* Shared libraries linked by the iPhone, keyboard and Mac Xcode targets.
 SwiftPM tests cover the approved saved-vault and workspace presentation seams.
 fast-core CI selects the portable core on Linux; Apple builds keep every target. */
import PackageDescription

// The Linux lane reuses the real storage/projection implementation and tests.
// Platform adapters and hardware budgets remain covered by macOS CI.
#if os(Linux)
let products: [Product] = [.library(name: "MindMachineCore", targets: ["MindMachineCore"])]
let targets: [Target] = [
    .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"),
    .target(name: "MindMachineCore", dependencies: ["CSQLite"],
            exclude: ["PrivateCloudSync.swift", "PrivateSyncKey.swift", "ProcessMemory.swift"]),
    .testTarget(name: "MindMachineCoreTests", dependencies: ["MindMachineCore"],
                exclude: ["ReplicationTests.swift", "SearchPerformanceTests.swift"])
]
#else
let products: [Product] = [
    .library(name: "MindMachineCore", targets: ["MindMachineCore"]),
    .library(name: "MindMachineUI", targets: ["MindMachineUI"]),
    .executable(name: "VaultIntegrityProbe", targets: ["VaultIntegrityProbe"])
]
let targets: [Target] = [
    .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"),
    .target(name: "MindMachineCore", dependencies: ["CSQLite"]),
    .target(name: "MindMachineUI", dependencies: ["MindMachineCore"]),
    .executableTarget(name: "VaultIntegrityProbe", dependencies: ["MindMachineCore"]),
    .testTarget(name: "MindMachineCoreTests", dependencies: ["MindMachineCore"]),
    .testTarget(name: "MindMachineUITests", dependencies: ["MindMachineUI", "MindMachineCore"])
]
#endif

let package = Package(
    name: "MindMachineCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    targets: targets
)
