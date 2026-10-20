// swift-tools-version: 5.9
/* Shared libraries linked by the iPhone, keyboard and Mac Xcode targets.
 SwiftPM tests cover the approved saved-vault and workspace presentation seams. */
import PackageDescription

let package = Package(
    name: "SecondBrainCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SecondBrainCore", targets: ["SecondBrainCore"]),
        .library(name: "SecondBrainUI", targets: ["SecondBrainUI"])
    ],
    targets: [
        .target(name: "SecondBrainCore"),
        .target(name: "SecondBrainUI", dependencies: ["SecondBrainCore"]),
        .testTarget(name: "SecondBrainCoreTests", dependencies: ["SecondBrainCore"]),
        .testTarget(name: "SecondBrainUITests", dependencies: ["SecondBrainUI", "SecondBrainCore"])
    ]
)
