// swift-tools-version: 5.9
/* Pure logic for the Mac floating pill: state machine, geometry, position persistence and motion rules.
 It is a separate local package so `swift test --package-path native/Pill` runs on the macOS CI
 runner without touching the main package. Linked by the MindMachineMac Xcode target (see
 native/Scripts/generate_project.py) and used by the AppKit controller in native/Apps/Mac. */
import PackageDescription

let package = Package(
    name: "MindMachinePill",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "MindMachinePill", targets: ["MindMachinePill"])],
    targets: [
        .target(name: "MindMachinePill"),
        .testTarget(name: "MindMachinePillTests", dependencies: ["MindMachinePill"])
    ]
)
