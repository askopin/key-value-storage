// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeyValueStorage",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "KeyValueStorage",
            targets: ["KeyValueStorage"]
        )
    ],
    dependencies: [
         .package(url: "https://github.com/apple/swift-docc-plugin", branch: "main"),
    ],
    targets: [
        .target(
            name: "KeyValueStorage",
            path: "KeyValueStorage/Sources"
        ),
        .testTarget(
            name: "KeyValueStorageTests",
            dependencies: ["KeyValueStorage"],
            path: "KeyValueStorage/Tests"
        )
    ],
    swiftLanguageModes: [.v6]
)
