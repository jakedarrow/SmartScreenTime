// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmartScreenTimeMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SmartScreenTimeMac",
            targets: ["SmartScreenTimeMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SmartScreenTimeMac",
            dependencies: [],
            path: "Sources/SmartScreenTimeMac"
        )
    ]
)
