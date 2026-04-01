// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CapeForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CapeForge", targets: ["CapeForge"])
    ],
    targets: [
        .executableTarget(
            name: "CapeForge",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CapeForgeTests",
            dependencies: ["CapeForge"],
            path: "Tests"
        )
    ]
)
