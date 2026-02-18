// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FancyZones",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FancyZones", targets: ["FancyZones"]),
        .library(name: "FancyZonesCore", targets: ["FancyZonesCore"]),
    ],
    targets: [
        // Pure logic library — no AppKit dependency, fully testable
        .target(
            name: "FancyZonesCore",
            dependencies: [],
            path: "Sources/FancyZonesCore"
        ),
        // Main executable — depends on the core library
        .executableTarget(
            name: "FancyZones",
            dependencies: ["FancyZonesCore"],
            path: "Sources/FancyZones"
        ),
        // Standalone test runner (no XCTest dependency)
        .executableTarget(
            name: "FancyZonesCoreTests",
            dependencies: ["FancyZonesCore"],
            path: "Tests/FancyZonesCoreTests"
        ),
    ]
)
