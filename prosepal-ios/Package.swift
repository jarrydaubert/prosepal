// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ProsePalNative",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ProsePalDomain", targets: ["ProsePalDomain"]),
        .library(name: "ProsePalAPI", targets: ["ProsePalAPI"]),
        .library(name: "ProsePalUI", targets: ["ProsePalUI"])
    ],
    targets: [
        .target(name: "ProsePalDomain"),
        .target(
            name: "ProsePalAPI",
            dependencies: ["ProsePalDomain"]
        ),
        .target(
            name: "ProsePalUI",
            dependencies: ["ProsePalAPI", "ProsePalDomain"]
        ),
        .testTarget(
            name: "ProsePalDomainTests",
            dependencies: ["ProsePalDomain"]
        ),
        .testTarget(
            name: "ProsePalAPITests",
            dependencies: ["ProsePalAPI", "ProsePalDomain"]
        ),
        .testTarget(
            name: "ProsePalUITests",
            dependencies: ["ProsePalUI", "ProsePalDomain"]
        )
    ]
)
