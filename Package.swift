// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Extracta",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.executable(name: "Extracta", targets: ["Extracta"])],
    targets: [
        .executableTarget(name: "Extracta", path: "Sources"),
        .testTarget(name: "ExtractaTests", dependencies: ["Extracta"], path: "Tests")
    ]
)
