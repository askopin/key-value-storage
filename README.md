> [!IMPORTANT]  
> This is a sample PoC project. Not intended for any real usage.

# KeyValueStorage Framework

A thread-safe, in-memory key-value storage framework for iOS, macOS, and watchOS, built with Swift 6 strict concurrency.

Documentation is available at
[kvs.askopin.com](http://kvs.askopin.com/documentation/keyvaluestorage/)

## Features

- **Efficient Prefix Search**: O(k + m) prefix-based key lookup using radix tree indexing
- **Random Value Retrieval**: Get a random stored value in O(1) time
- **Thread-Safe**: Built with Swift actors for automatic thread-safety
- **Type-Safe**: Generic API supporting any `Sendable & Codable` type
- **Zero Dependencies**: No external dependencies, pure Swift implementation
- **Multiple Platforms**: iOS 16+, macOS 13+, watchOS 9+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/askopin/key-value-storage.git", from: "0.1.0")
]
```

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'KeyValueStorage', '~> 0.1'
```

## Usage

### Quick Start

```swift
import KeyValueStorage

// Create a storage instance with default configuration
let storage = StorageProvider.inMemory()

// Store values
try await storage.put("Tokyo", forKey: "city:japan:capital")
try await storage.put(13960000, forKey: "city:tokyo:population")
try await storage.put(35.6762, forKey: "city:tokyo:latitude")

// Retrieve values
let city: String? = await storage.get(forKey: "city:japan:capital")
let population: Int? = await storage.get(forKey: "city:tokyo:population")

// Delete values
await storage.delete(forKey: "city:japan:capital")

// Clear all
await storage.clear()
```

### Configuration

The framework allows customization through `StorageConfiguration`:

```swift
// Create a custom configuration
let config = StorageConfiguration.inMemory(
    maxKeySize: 2048,              // 2KB key limit (default: 1024)
    indexImplementation: .radix    // Use radix tree for prefix indexing (default)
)

let storage = StorageProvider.storage(configuration: config)
```

#### Index Implementation Options

Choose the prefix index implementation based on your use case:

**Radix Tree (`.radix`)** - Default
- More memory-efficient for sparse key spaces with common prefixes
- Better performance for prefix search operations
- Recommended for most use cases

**Set-Based Index (`.set`)**
- Better performance for insert/delete operations
- More suitable for smaller datasets or when prefix search is less frequent

```swift
// Using set-based index for frequent inserts/deletes
let config = StorageConfiguration.inMemory(indexImplementation: .set)
let storage = StorageProvider.storage(configuration: config)
```

### Prefix Search

```swift
// Store keys with common prefixes
try await storage.put("Paris", forKey: "city:france:capital")
try await storage.put(2161000, forKey: "city:paris:population")
try await storage.put(105.4, forKey: "city:paris:area_km2")

// Search by prefix (returns sorted results)
let cityKeys = await storage.keys(withPrefix: "city:paris")
// Returns: ["city:paris:area_km2", "city:paris:population"]

// Get all keys
let allKeys = await storage.allKeys
```

### Random Value Retrieval

```swift
try await storage.put("Berlin", forKey: "city:germany")
try await storage.put("Rome", forKey: "city:italy")

let randomValue: String? = await storage.getRandomValue()
// Returns one of: "Berlin", "Rome", or nil if empty
```

### Custom Types

```swift
struct CityInfo: Sendable, Codable {
    let name: String
    let country: String
    let population: Int
}

let cityInfo = CityInfo(name: "London", country: "United Kingdom", population: 8982000)
try await storage.put(cityInfo, forKey: "city:uk:capital")

let retrieved: CityInfo? = await storage.get(forKey: "city:uk:capital")
```

### Error Handling

```swift
do {
    try await storage.put("value", forKey: "")
} catch StorageError.emptyKey {
    print("Key cannot be empty")
} catch StorageError.keyTooLarge(let size, let limit) {
    print("Key size \(size) exceeds limit \(limit)")
}
```

## API Reference

### KeyValueStorage Protocol

```swift
protocol KeyValueStorage: Sendable {
    func put<T: Sendable & Codable>(_ value: T, forKey key: String) async throws
    func get<T: Sendable & Codable>(forKey key: String, as type: T.Type) async -> T?
    func delete(forKey key: String) async
    func getRandomValue<T: Sendable & Codable>(as type: T.Type) async -> T?
    func keys(withPrefix prefix: String) async -> [String]
    var allKeys: [String] { get async }
    var count: Int { get async }
    func clear() async
}
```

### Storage Errors

```swift
enum StorageError: Error {
    case emptyKey
    case keyTooLarge(size: Int, limit: Int)
    case valueTooLarge(size: Int, limit: Int)
    case encodingFailed(Error)
}
```

### Constraints

- Keys must be non-empty strings
- Key length is limited (default: 1KB, configurable via `StorageConfiguration.maxKeySize`)
- Values must conform to `Sendable & Codable`
- Prefix search is case-sensitive
- Results from prefix search are sorted alphabetically


### Performance Characteristics

### Radix tree index
| Operation         | Complexity | Notes                                    |
|-------------------|------------|------------------------------------------|
| put               | O(k) avg   | O(k) for prefix index update             |
| get               | O(1) avg   | Direct dictionary lookup                 |
| delete            | O(k) avg   | O(k) for prefix index removal            |
| getRandomValue    | O(k)       | Uses dictionary's random element         |
| keys(withPrefix:) | O(k + m)   | k = max key length, m = matches          |
| allKeys           | O(n)       | n = total keys. Uses dictionary keys set |
| count             | O(1)       | Dictionary count property                |

### Set index
| Operation         | Complexity | Notes                                   |
|-------------------|------------|-----------------------------------------|
| put               | O(1) avg   | Set updates in constant time on average |
| get               | O(1) avg   | Direct dictionary lookup                |
| delete            | O(1) avg   | Set updates in constant time on average |
| getRandomValue    | O(n)       | Uses set random element                 |
| keys(withPrefix:) | O(n)       | n = total keys                          |
| allKeys           | O(n)       | n = total keys                          |
| count             | O(1)       | Dictionary count property               |


## Demo App

A demo iOS app is included to showcase all framework capabilities:

- Add/remove key-value pairs
- Search by prefix
- Get random values
- View all stored entries
- Clear all data

Demo app supports iOS 18+ devices/simulators

## Requirements

- Swift 6.0+
- Xcode 16.2+
- iOS 16.0+ / macOS 13.0+

## Development

The project uses [Tuist](https://tuist.io) for project generation and development workflow.

### Setup

Generate the Xcode project:

```bash
tuist generate
```

### Running Tests

The framework includes comprehensive unit tests covering:

Test coverage includes:
- CRUD operations for all data types
- Prefix search with various patterns
- Edge cases (empty storage, unicode, special characters)
- Error handling (invalid inputs, size limits)
- Thread safety and concurrency
- Type mismatches and nil handling

```bash
tuist test --no-selective-testing --platform iOS
```

Test results: 46 tests, all passing
- InMemoryStorage: 28 tests
- RadixTree: 18 tests
  - Basic Functions: 11 tests
  - Tree Structure: 7 tests

## License

MIT License - see LICENSE file for details

## Author

Anton Skopin