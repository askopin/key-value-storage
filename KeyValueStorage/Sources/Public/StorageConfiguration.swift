/// Configuration options for key-value storage instances.
///
/// This type defines the behavior and performance characteristics of storage instances.
///
/// ## In memory storage
/// ### Performance Characteristics
///
/// Storage operations have the following complexity guarantees:
/// - **put**: O(1) average, O(k) for prefix index where k is key length
/// - **get**: O(1) average
/// - **delete**: O(1) average, O(k) for prefix index where k is key length
/// - **getRandomValue**: O(1)
/// - **keys(withPrefix:)**: O(k + m log m) where k is prefix length and m is number of matches
/// - **allKeys**: O(n log n) where n is number of stored keys
/// - **count**: O(1)
/// - **clear**: O(n) where n is number of stored keys
///
/// ## Index Implementation Trade-offs
///
/// The `indexImplementation` option allows choosing between different prefix index data structures:
/// - **Radix tree** (default): More memory-efficient for sparse key spaces with common prefixes, performs better on fetch requests
/// - **Set**: Simpler implementation,  performs better on insert/delete operations and for smaller datasets
///
/// ## Usage Example
/// ```swift
/// let config = StorageConfiguration.inMemory(
///     maxKeySize: 2048,
///     indexImplementation: .radix
/// )
/// let storage = StorageProvider.storage(configuration: config)
///
/// try await storage.put("Tokyo", forKey: "city:japan:capital")
/// try await storage.put(13960000, forKey: "city:tokyo:population")
/// ```
public struct StorageConfiguration {
    static let defaultMaxKeySize: UInt = 1024 // 1KB

    /// Defines the storage backend behavior.
    public enum Behavior {
        /// Store data in memory only. Data is lost when the process terminates.
        case inMemory
    }

    /// Defines the prefix index data structure implementation.
    ///
    /// Different implementations offer different performance characteristics
    /// depending on your key patterns and dataset size.
    public enum IndexImplementation {
        /// Use a radix tree for the prefix index. More memory-efficient for sparse key spaces with common prefixes, performs better on fetch requests
        case radix
        /// Use a set-based index.  Performs better on insert/delete operations and for smaller datasets
        case set
    }

    /// The storage backend behavior (e.g., in-memory, persistent).
    let behavior: Behavior
    /// The prefix index implementation to use.
    let indexImplementation: IndexImplementation
    /// The maximum allowed key size in bytes.
    let maxKeySize: UInt

    /// Creates a new storage configuration.
    ///
    /// - Parameters:
    ///   - behavior: The storage backend behavior.
    ///   - maxKeySize: The maximum allowed key size in bytes. Defaults to 1024 bytes if not specified.
    ///   - indexImplementation: The prefix index implementation. Defaults to `.radix`.
    public init(
        behavior: Behavior,
        maxKeySize: UInt? = nil,
        indexImplementation: IndexImplementation = .radix
    ) {
        self.behavior = behavior
        self.maxKeySize = maxKeySize ?? Self.defaultMaxKeySize
        self.indexImplementation = indexImplementation
    }

    /// Creates a configuration for in-memory storage.
    ///
    /// This is a convenience factory method for creating in-memory storage configurations.
    ///
    /// - Parameters:
    ///   - maxKeySize: The maximum allowed key size in bytes. Defaults to 1024 bytes if not specified.
    ///   - indexImplementation: The prefix index implementation. Defaults to `.radix`.
    /// - Returns: A configuration for in-memory storage with the specified settings.
    public static func inMemory(
        maxKeySize: UInt? = nil,
        indexImplementation: IndexImplementation = .radix
    ) -> Self {
        StorageConfiguration(
            behavior: .inMemory,
            maxKeySize: maxKeySize ?? defaultMaxKeySize,
            indexImplementation: indexImplementation
        )
    }
}
