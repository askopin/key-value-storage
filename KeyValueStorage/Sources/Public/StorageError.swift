/// Errors that can occur during storage operations.
public enum StorageError: Error, Sendable {
    /// The provided key is empty, which is not allowed.
    case emptyKey

    /// The provided key exceeds the maximum size limit (1024 bytes).
    case keyTooLarge(size: Int, limit: UInt)
}

extension StorageError: CustomStringConvertible {
    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .emptyKey:
            return "Key cannot be empty"
        case .keyTooLarge(let size, let limit):
            return "Key size (\(size) bytes) exceeds limit (\(limit) bytes)"
        }
    }
}
