import Foundation

actor InMemoryStorage: KeyValueStorage {
    private let maxKeySize: UInt
    private var storage: [String: any Sendable]
    private var prefixIndex: PrefixIndex

    public init(prefixIndex: PrefixIndex, maxKeySize: UInt) {
        self.storage = [:]
        self.prefixIndex = prefixIndex
        self.maxKeySize = maxKeySize
    }

    public func put<T: Sendable & Codable>(_ value: T, forKey key: String) async throws {
        try validateKey(key)
        storage[key] = value
        prefixIndex.insert(key)
    }

    public func get<T: Sendable & Codable>(forKey key: String, as type: T.Type) async -> T? {
        guard let value = storage[key] else {
            return nil
        }

        return value as? T
    }

    func get(forKey key: String) async -> Sendable? {
        storage[key]
    }

    public func delete(forKey key: String) async {
        storage.removeValue(forKey: key)
        prefixIndex.remove(key)
    }

    func getRandomValue() async -> Sendable? {
        guard let key = prefixIndex.randomElement() else {
            return nil
        }

        return storage[key]
    }

    public func keys(withPrefix prefix: String) async -> [String] {
        let matchingKeys = prefixIndex.keysWithPrefix(prefix)
        return matchingKeys.sorted()
    }

    public var allKeys: [String] {
        get async {
            Array(storage.keys)
        }
    }

    public var count: Int {
        get async {
            storage.count
        }
    }

    public func clear() async {
        storage.removeAll()
        prefixIndex.removeAll()
    }

    private func validateKey(_ key: String) throws {
        if key.isEmpty {
            throw StorageError.emptyKey
        }

        let keySize = key.utf8.count
        if keySize > maxKeySize {
            throw StorageError.keyTooLarge(size: keySize, limit: maxKeySize)
        }
    }
}
