// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MCPManagerMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MCPManagerMac", targets: ["MCPManagerMac"])
    ],
    targets: [
        .executableTarget(
            name: "MCPManagerMac",
            path: "Sources/MCPManagerMac"
        )
    ]
)
