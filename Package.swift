// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPv64",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "IPv64", targets: ["IPv64"]),
    ],
    targets: [
        .target(name: "IPv64"),
        .testTarget(name: "IPv64Tests", dependencies: ["IPv64"]),
    ],
    swiftLanguageModes: [.v6]
)
