// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyValueStorageBenchmark",
    platforms: [.macOS("13.0")],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.0.0")),
        .package(name: "KeyValueStorage", path: "../..")
    ]
)

// Benchmark of KeyValueStorageBenchmark
package.targets += [
    .executableTarget(
        name: "KeyValueStorageBenchmark",
        dependencies: [
            .product(name: "Benchmark", package: "package-benchmark"),
            .product(name: "KeyValueStorage", package: "KeyValueStorage"),
        ],
        path: "Benchmarks/KeyValueStorageBenchmark",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]
