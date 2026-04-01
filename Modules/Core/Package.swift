// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "LocalPersistence", targets: ["LocalPersistence"]),
    ],
    targets: [
        .target(
            name: "Networking",
            path: "Sources/Networking"
        ),
        .target(
            name: "LocalPersistence",
            path: "Sources/LocalPersistence",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            path: "Tests/NetworkingTests"
        ),
        .testTarget(
            name: "LocalPersistenceTests",
            dependencies: ["LocalPersistence"],
            path: "Tests/LocalPersistenceTests"
        ),
    ]
)
