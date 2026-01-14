# Quick Start

Learn how to store, retrieve, and manage key-value data with KeyValueStorage.

## Overview

KeyValueStorage provides a thread-safe, async-first key-value storage solution with support for prefix-based key lookups. This guide covers the essential operations to get you started.

## Creating a Storage Instance

Start by creating a storage instance using ``StorageProvider``:

```swift
import KeyValueStorage

// Create an in-memory storage with default configuration
let storage = StorageProvider.inMemory()
```

For custom configurations, use ``StorageConfiguration``:

```swift
let config = StorageConfiguration.inMemory(
    maxKeySize: 2048,              // 2KB key limit (default: 1024)
    indexImplementation: .radix    // Radix tree for prefix indexing (default)
)

let storage = StorageProvider.storage(configuration: config)
```

## Storing Values

Use the ``KeyValueStorage/put(_:forKey:)`` method to store values. The storage accepts any type that conforms to both `Sendable` and `Codable`:

```swift
// Store primitive types
try await storage.put("Tokyo", forKey: "city:japan:capital")
try await storage.put(13_960_000, forKey: "city:tokyo:population")
try await storage.put(35.6762, forKey: "city:tokyo:latitude")
try await storage.put(true, forKey: "city:tokyo:isCapital")

// Store arrays and dictionaries
try await storage.put(["Shinjuku", "Shibuya", "Ginza"], forKey: "city:tokyo:districts")
try await storage.put(["timezone": "JST", "currency": "JPY"], forKey: "city:tokyo:metadata")
```

### Storing Custom Types

Store your own types by conforming to `Sendable` and `Codable`:

```swift
struct CityInfo: Sendable, Codable {
    let name: String
    let country: String
    let population: Int
    let coordinates: Coordinates

    struct Coordinates: Sendable, Codable {
        let latitude: Double
        let longitude: Double
    }
}

let tokyo = CityInfo(
    name: "Tokyo",
    country: "Japan",
    population: 13_960_000,
    coordinates: .init(latitude: 35.6762, longitude: 139.6503)
)

try await storage.put(tokyo, forKey: "city:tokyo:info")
```

### Overwriting Values

Storing a value with an existing key replaces the previous value:

```swift
try await storage.put("England", forKey: "city:london:country")
try await storage.put("United Kingdom", forKey: "city:london:country")

let country: String? = await storage.get(forKey: "city:london:country")
// country == "United Kingdom"
```

## Retrieving Values

### Type-Safe Retrieval

Use ``KeyValueStorage/get(forKey:as:)`` or the type-inferred ``KeyValueStorage/get(forKey:)`` to retrieve values:

```swift
// With explicit type annotation (type inference)
let city: String? = await storage.get(forKey: "city:japan:capital")
let population: Int? = await storage.get(forKey: "city:tokyo:population")
let latitude: Double? = await storage.get(forKey: "city:tokyo:latitude")

// With explicit type parameter
let info = await storage.get(forKey: "city:tokyo:info", as: CityInfo.self)
```

### Handling Non-Existent Keys

When a key doesn't exist, `get` returns `nil`:

```swift
let missing: String? = await storage.get(forKey: "nonexistent:key")
// missing == nil
```

### Type Mismatch Handling

If the stored value doesn't match the requested type, `nil` is returned:

```swift
try await storage.put("text value", forKey: "myKey")

let wrongType: Int? = await storage.get(forKey: "myKey")
// wrongType == nil (stored as String, requested as Int)

let correctType: String? = await storage.get(forKey: "myKey")
// correctType == "text value"
```

### Type-Erased Retrieval

For cases where you don't know the type at compile time:

```swift
let value = await storage.get(forKey: "someKey")
// value is Sendable?

if let stringValue = value as? String {
    print("It's a string: \(stringValue)")
} else if let intValue = value as? Int {
    print("It's an integer: \(intValue)")
}
```

### Random Value Retrieval

Get a randomly selected value from storage:

```swift
try await storage.put("Tokyo", forKey: "city:1")
try await storage.put("Paris", forKey: "city:2")
try await storage.put("London", forKey: "city:3")

let randomCity = await storage.getRandomValue() as? String
// randomCity is one of: "Tokyo", "Paris", or "London"
```

## Deleting Values

Remove a single value with ``KeyValueStorage/delete(forKey:)``:

```swift
await storage.delete(forKey: "city:tokyo:population")

let deleted: Int? = await storage.get(forKey: "city:tokyo:population")
// deleted == nil
```

Deleting a non-existent key is a no-op and doesn't throw:

```swift
await storage.delete(forKey: "nonexistent:key") // No error
```

## Clearing Storage

Remove all values with ``KeyValueStorage/clear()``:

```swift
try await storage.put("value1", forKey: "key1")
try await storage.put("value2", forKey: "key2")

await storage.clear()

let count = await storage.count
// count == 0
```

## Prefix-Based Key Queries

One of KeyValueStorage's key features is efficient prefix-based key lookups.

### Finding Keys by Prefix

Use ``KeyValueStorage/keys(withPrefix:)`` to find all keys starting with a given prefix:

```swift
try await storage.put(13_960_000, forKey: "city:tokyo:population")
try await storage.put(35.6762, forKey: "city:tokyo:latitude")
try await storage.put(139.6503, forKey: "city:tokyo:longitude")
try await storage.put(2_161_000, forKey: "city:paris:population")
try await storage.put(48.8566, forKey: "city:paris:latitude")

// Find all Tokyo-related keys
let tokyoKeys = await storage.keys(withPrefix: "city:tokyo")
// ["city:tokyo:latitude", "city:tokyo:longitude", "city:tokyo:population"]

// Find all city keys
let cityKeys = await storage.keys(withPrefix: "city:")
// All 5 keys, sorted alphabetically

// Find all population keys across cities
let populationKeys = await storage.keys(withPrefix: "city:").filter { $0.hasSuffix(":population") }
// ["city:paris:population", "city:tokyo:population"]
```

### Getting All Keys

Use the ``KeyValueStorage/allKeys`` property or pass an empty prefix:

```swift
// Using property
let allKeys = await storage.allKeys

// Equivalent to:
let allKeysAlt = await storage.keys(withPrefix: "")
```

Keys are always returned in alphabetical (lexicographic) order.

### Key Naming Conventions

For effective prefix queries, use hierarchical key naming:

```swift
// Recommended: Use colons or slashes as separators
"user:123:profile"
"user:123:settings"
"user:123:preferences:theme"

// Alternative: Dot notation
"app.config.feature.enabled"
"app.config.theme.dark"

// This enables efficient queries:
let userKeys = await storage.keys(withPrefix: "user:123:")
let configKeys = await storage.keys(withPrefix: "app.config.")
```

## Checking Storage State

### Count

Get the number of stored key-value pairs:

```swift
let count = await storage.count
print("Storage contains \(count) items")
```

## Error Handling

KeyValueStorage operations can throw ``StorageError``:

```swift
do {
    try await storage.put("value", forKey: "myKey")
} catch StorageError.emptyKey {
    print("Key cannot be empty")
} catch StorageError.keyTooLarge(let size, let limit) {
    print("Key size \(size) exceeds limit of \(limit) bytes")
} catch {
    print("Unexpected error: \(error)")
}
```

### Key Validation

Keys must be non-empty and within the size limit:

```swift
// Empty keys throw an error
try await storage.put("value", forKey: "") // Throws StorageError.emptyKey

// Keys exceeding the limit throw an error
let longKey = String(repeating: "a", count: 2000)
try await storage.put("value", forKey: longKey) // Throws StorageError.keyTooLarge
```

## Thread Safety

KeyValueStorage is fully thread-safe. You can safely perform concurrent operations:

```swift
await withTaskGroup(of: Void.self) { group in
    // Concurrent writes
    for i in 0..<100 {
        group.addTask {
            try? await storage.put(i, forKey: "concurrent:\(i)")
        }
    }

    // Concurrent reads
    for i in 0..<100 {
        group.addTask {
            let _: Int? = await storage.get(forKey: "concurrent:\(i)")
        }
    }
}
```

## Configuration Options

### Index Implementation

Choose between two prefix index implementations:

```swift
// Radix tree (default): Better for large datasets with common prefixes
let radixConfig = StorageConfiguration.inMemory(indexImplementation: .radix)

// Set-based: Simpler, better for smaller datasets or frequent inserts/deletes
let setConfig = StorageConfiguration.inMemory(indexImplementation: .set)
```

**Radix Tree** (`.radix`):
- More memory-efficient for sparse key spaces with common prefixes
- Better performance for prefix lookups
- Recommended for most use cases

**Set-Based** (`.set`):
- Simpler implementation with predictable performance
- Better for smaller datasets
- Faster insert/delete operations

### Maximum Key Size

Configure the maximum allowed key size in bytes:

```swift
let config = StorageConfiguration.inMemory(
    maxKeySize: 4096  // 4KB limit
)
```

The default limit is 1024 bytes (1KB).

## Complete Example

Here's a complete example demonstrating the key features:

```swift
import KeyValueStorage

struct UserProfile: Sendable, Codable {
    let id: String
    let name: String
    let email: String
}

actor ProfileStore {
    private let storage: KeyValueStorage

    init() {
        let config = StorageConfiguration.inMemory(
            maxKeySize: 512,
            indexImplementation: .radix
        )
        self.storage = StorageProvider.storage(configuration: config)
    }

    func save(profile: UserProfile) async throws {
        try await storage.put(profile, forKey: "user:\(profile.id):profile")
        try await storage.put(Date(), forKey: "user:\(profile.id):lastUpdated")
    }

    func get(userId: String) async -> UserProfile? {
        await storage.get(forKey: "user:\(userId):profile", as: UserProfile.self)
    }

    func delete(userId: String) async {
        let keys = await storage.keys(withPrefix: "user:\(userId):")
        for key in keys {
            await storage.delete(forKey: key)
        }
    }

    func allUserIds() async -> [String] {
        await storage.keys(withPrefix: "user:")
            .filter { $0.hasSuffix(":profile") }
            .compactMap { key in
                // Extract user ID from "user:{id}:profile"
                let components = key.split(separator: ":")
                guard components.count >= 2 else { return nil }
                return String(components[1])
            }
    }
}

// Usage
let store = ProfileStore()

let profile = UserProfile(id: "123", name: "Alice", email: "alice@example.com")
try await store.save(profile: profile)

if let retrieved = await store.get(userId: "123") {
    print("Found user: \(retrieved.name)")
}

let allUsers = await store.allUserIds()
print("All users: \(allUsers)")
```