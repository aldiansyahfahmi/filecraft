// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FileCraft",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FileCraft", targets: ["FileCraft"])
    ],
    targets: [
        .executableTarget(
            name: "FileCraft",
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        )
    ]
)
