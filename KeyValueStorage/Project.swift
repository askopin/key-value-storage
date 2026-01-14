import ProjectDescription

let project = Project(
    name: "KeyValueStorage",
    targets: [
        .target(
            name: "KeyValueStorage",
            destinations: [.iPhone, .iPad, .mac, .appleWatch],
            product: .framework,
            bundleId: "com.askopin.KeyValueStorage",
            deploymentTargets: .multiplatform(
                iOS: "16.0",
                macOS: "13.0",
                watchOS: "9.0"
            ),
            infoPlist: .default,
            sources: ["Sources/**"],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ]
            )
        ),
        .target(
            name: "KeyValueStorageTests",
            destinations: [.iPhone, .iPad, .mac, .appleWatch],
            product: .unitTests,
            bundleId: "com.askopin.KeyValueStorageTests",
            deploymentTargets: .multiplatform(
                iOS: "16.0",
                macOS: "13.0",
                watchOS: "9.0"
            ),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "KeyValueStorage")
            ]
        )
    ]
)
