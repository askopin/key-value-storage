# Installation

Learn how to add KeyValueStorage to your Swift project.

## Overview

KeyValueStorage supports multiple integration methods. Choose the one that best fits your project setup.

## Requirements

Before installing, ensure your project meets the following requirements:

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 16.0            |
| macOS    | 13.0            |

- **Xcode**: 26.0 or later

## Swift Package Manager

Swift Package Manager is the recommended way to integrate KeyValueStorage.

### Using Xcode

1. Open your project in Xcode
2. Navigate to **File → Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/askopin/key-value-storage.git
   ```
4. Select the version rule (e.g., "Up to Next Major Version" from `1.0.0`)
5. Click **Add Package**
6. Select the `KeyValueStorage` library and add it to your target

### Using Package.swift

Add KeyValueStorage as a dependency in your `Package.swift` file:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    dependencies: [
        .package(
            url: "https://github.com/askopin/key-value-storage.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "KeyValueStorage", package: "key-value-storage")
            ]
        )
    ]
)
```

### Version Selection

KeyValueStorage follows [Semantic Versioning](https://semver.org/). You can specify version requirements in several ways:

```swift
// Recommended: Up to next major version
.package(url: "https://github.com/askopin/key-value-storage.git", from: "0.1.0")

// Exact version
.package(url: "https://github.com/askopin/key-value-storage.git", exact: "0.1.0")

// Version range
.package(url: "https://github.com/askopin/key-value-storage.git", "0.1.0"..<"1.0.0")

// Branch (for development only)
.package(url: "https://github.com/askopin/key-value-storage.git", branch: "main")
```

## Tuist Integration

If you're using [Tuist](https://tuist.io/) for project generation, add KeyValueStorage to your project configuration.

### Package.swift (Tuist)

Create or update your `Tuist/Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourApp",
    dependencies: [
        .package(
            url: "https://github.com/askopin/key-value-storage.git",
            from: "1.0.0"
        )
    ]
)
```

### Project.swift

Reference the dependency in your target:

```swift
import ProjectDescription

let project = Project(
    name: "YourApp",
    targets: [
        .target(
            name: "YourApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.yourcompany.yourapp",
            deploymentTargets: .multiplatform(
                iOS: "16.0",
                macOS: "13.0"
            ),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "KeyValueStorage")
            ]
        )
    ]
)
```

Then run:

```bash
tuist install
tuist generate
```

## Verifying the Installation

After installation, verify that KeyValueStorage is correctly integrated:

```swift
import KeyValueStorage

// Create a storage instance
let storage = StorageProvider.inMemory()

// Test basic operations
Task {
    do {
        try await storage.put("Hello, World!", forKey: "greeting")
        let greeting: String? = await storage.get(forKey: "greeting")
        print(greeting ?? "Installation verification failed")
    } catch {
        print("Error: \(error)")
    }
}
```

If the code compiles and runs without errors, the installation was successful.

## Troubleshooting

### Common Issues

**"No such module 'KeyValueStorage'"**
- Ensure the package has been fetched: **File → Packages → Resolve Package Versions**
- Verify the library is added to your target's dependencies
- Clean the build folder: **Product → Clean Build Folder** (⇧⌘K)

**Platform version mismatch**
- Check that your deployment target meets the minimum requirements (iOS 16.0, macOS 13.0, or watchOS 9.0)
- Update your project's deployment target if necessary

**Swift version conflicts**
- KeyValueStorage requires Swift 6.0. Ensure your project uses a compatible Swift version
- Check your build settings for `SWIFT_VERSION`

## Next Steps

Once installed, proceed to <doc:QuickStart> to learn how to use KeyValueStorage in your application.
