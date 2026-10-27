// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EisuMapping",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "EisuMapping", targets: ["EisuMapping"])],
    targets: [
        .target(name: "KeyMapping"),
        .executableTarget(name: "EisuMapping", dependencies: ["KeyMapping"]),
        .testTarget(name: "KeyMappingTests", dependencies: ["KeyMapping"]),
    ]
)
