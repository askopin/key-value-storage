import Foundation

/// A thread-safe key-value storage interface supporting any value types
/// and efficient prefix-based key lookup.
///
/// ## Value Type Requirements
/// Values must conform to:
/// - `Sendable` - for thread-safe concurrent access
/// - `Codable` - for serialization to/from Data (enables future persistence)
///
/// ## Usage Example
/// ```swift
/// let storage: any KeyValueStorage = StorageProvider.inMemory()
///
/// // Store values of any Sendable & Codable type
/// try await storage.put("Tokyo", forKey: "city:capital:japan")
/// try await storage.put(35.6762, forKey: "city:tokyo:latitude")
/// try await storage.put(13960000, forKey: "city:tokyo:population")
/// try await storage.put(CityInfo(...), forKey: "city:tokyo:info")
///
/// // Retrieve values with type
/// let city: String? = await storage.get(forKey: "city:capital:japan")
/// let latitude: Double? = await storage.get(forKey: "city:tokyo:latitude")
///
/// // Search by prefix
/// let tokyoKeys = await storage.keys(withPrefix: "city:tokyo")
/// ```
public protocol KeyValueStorage: Sendable {

    /// Stores a value for the specified key.
    ///
    /// If a value already exists for the key, it is replaced.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key to associate with the value. Must be non-empty.
    /// - Throws: `StorageError` if validation fails or encoding errors occur.
    func put<T: Sendable & Codable>(_ value: T, forKey key: String) async throws

    /// Retrieves the value associated with the specified key.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - type: The expected type of the value.
    /// - Returns: The stored value if it exists and matches the type, otherwise `nil`.
    func get<T: Sendable & Codable>(forKey key: String, as type: T.Type) async -> T?

    /// Retrieves the value associated with the specified key.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    /// - Returns: The stored value if it exists, otherwise `nil`.
    func get(forKey key: String) async -> Sendable?

    /// Removes the value associated with the specified key.
    ///
    /// If no value exists for the key, this method does nothing
    ///
    /// - Parameter key: The key to remove.
    func delete(forKey key: String) async


    /// Returns a randomly selected stored value.
    ///
    /// - Returns: A random value from storage, or `nil` if storage is empty
    /// - Note: The distribution gurarnteed to be uniform across all stored values.
    func getRandomValue() async -> Sendable?

    /// Returns all keys that start with the specified prefix in alphabetical order.
    ///
    /// - Parameter prefix: The prefix to match. An empty string matches all keys.
    /// - Returns: An array of matching keys in lexicographic order.
    func keys(withPrefix prefix: String) async -> [String]

    /// Returns all keys currently stored in alphabetical order.
    ///
    /// Equivalent to `keys(withPrefix: "")`.
    ///
    /// - Returns: An array of all stored keys in lexicographic order.
    var allKeys: [String] { get async }

    /// Returns the number of key-value pairs in storage.
    var count: Int { get async }

    /// Removes all key-value pairs from storage.
    func clear() async
}

extension KeyValueStorage {

    /// Retrieves the value for the specified key, inferring the type.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored value if it exists and matches the inferred type.
    public func get<T: Sendable & Codable>(forKey key: String) async -> T? {
        await get(forKey: key, as: T.self)
    }
}
