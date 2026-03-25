// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacMouseCursor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacMouseCursor", targets: ["MacMouseCursor"]),
        .executable(name: "CursorDiagnostics", targets: ["CursorDiagnostics"])
    ],
    targets: [
        .executableTarget(
            name: "MacMouseCursor",
            path: "Sources"
        ),
        .executableTarget(
            name: "CursorDiagnostics",
            path: "Diagnostics"
        ),
        .testTarget(
            name: "MacMouseCursorTests",
            dependencies: ["MacMouseCursor"],
            path: "Tests"
        )
    ]
)
