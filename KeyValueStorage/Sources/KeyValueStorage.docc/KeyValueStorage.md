# ``KeyValueStorage``

A thread-safe, in-memory key-value storage framework for iOS, macOS, and watchOS, built with Swift 6 strict concurrency.

 **Features**

- **Efficient Prefix Search**: O(k + m) prefix-based key lookup using radix tree indexing
- **Random Value Retrieval**: Get a random stored value in O(1) time
- **Thread-Safe**: Built with Swift actors for automatic thread-safety
- **Type-Safe**: Generic API supporting any `Sendable & Codable` type
- **Zero Dependencies**: No external dependencies, pure Swift implementation
- **Multiple Platforms**: iOS 16+, macOS 13+, watchOS 9+

