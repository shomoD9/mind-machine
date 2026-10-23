// swift-tools-version: 5.9
/* Shared libraries linked by the iPhone, keyboard and Mac Xcode targets.
 SwiftPM tests cover the approved saved-vault and workspace presentation seams. */
import PackageDescription

let package = Package(
    name: "MindMachineCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MindMachineCore", targets: ["MindMachineCore"]),
        .library(name: "MindMachineUI", targets: ["MindMachineUI"]),
        .executable(name: "VaultIntegrityProbe", targets: ["VaultIntegrityProbe"])
    ],
    targets: [
        .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"),
        .target(name: "MindMachineCore", dependencies: ["CSQLite"]),
        .target(name: "MindMachineUI", dependencies: ["MindMachineCore"]),
        .executableTarget(name: "VaultIntegrityProbe", dependencies: ["MindMachineCore"]),
        .testTarget(name: "MindMachineCoreTests", dependencies: ["MindMachineCore"]),
        .testTarget(name: "MindMachineUITests", dependencies: ["MindMachineUI", "MindMachineCore"])
    ]
)
