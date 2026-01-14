import ProjectDescription

let project = Project(
    name: "KeyValueStorageDemo",
    targets: [
        .target(
            name: "KeyValueStorageDemo",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.askopin.KeyValueStorageDemo",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "KeyValueStorage", path: "../KeyValueStorage")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ]
            )
        )
    ]
)
