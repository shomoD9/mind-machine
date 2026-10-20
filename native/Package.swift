// swift-tools-version: 5.9
// Native foundation package for planned iPhone, keyboard and Mac targets.
// Tests exercise persistence-independent rules before platform delivery is added.
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
        .testTarget(name: "SecondBrainCoreTests", dependencies: ["SecondBrainCore"])
    ]
)
