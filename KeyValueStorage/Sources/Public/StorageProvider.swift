/// Factory for creating key-value storage instances.
///
/// Use this type to create storage instances with specific configurations
/// or to access pre-configured storage instances.
public struct StorageProvider {
    /// Creates a storage instance with the specified configuration.
    ///
    /// - Parameter configuration: The configuration defining storage behavior and performance characteristics.
    /// - Returns: A new storage instance configured according to the provided settings.
    public static func storage(configuration: StorageConfiguration) -> KeyValueStorage {
        let index: PrefixIndex
        switch configuration.indexImplementation {
        case .radix:
            index = RadixTree()
        case .set:
            index = SetIndex()
        }

        switch configuration.behavior {
        case .inMemory:
            return InMemoryStorage(prefixIndex: index, maxKeySize: configuration.maxKeySize)
        }
    }

    /// A pre-configured in-memory storage instance.
    ///
    /// This convenience function provides an in-memory storage with default settings:
    /// - Maximum key size: 1024 bytes
    /// - Index implementation: Radix tree
    public static func inMemory() -> KeyValueStorage {
        InMemoryStorage(prefixIndex: RadixTree(), maxKeySize: StorageConfiguration.defaultMaxKeySize)
    }
}
