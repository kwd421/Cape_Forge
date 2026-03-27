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
            path: "Sources"
        ),
        .testTarget(
            name: "CapeForgeTests",
            dependencies: ["CapeForge"],
            path: "Tests"
        )
    ]
)
