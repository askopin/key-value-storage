# Assessment notes

This notes do not really belong to the framework documentation, but rather represents some of my comments that, I believe, could be valuable for assessment evaluation.

## Architecture

### Protocol-Based Design

The framework uses a protocol (`KeyValueStorage`) to define the storage interface, enabling multiple implementations.
For now only `InMemoryStorage` implementation exists.

### Core Components

1. **KeyValueStorage Protocol** (``KeyValueStorage/KeyValueStorage``)
   - Defines the public API for all storage implementations
   - All methods are `async` for thread-safety
   - Generic over `Sendable & Codable` types

2. *StorageConfiguration*
   - Defines current behavior, potentially enabling persitent/multi-layered implementations without breaking changes
   - Allows to configure max key size and index implementation 
   
3. **InMemoryStorage Actor** (`Internal/InMemoryStorage.swift`)
   - Thread-safe actor providing serialized access
   - Dictionary for O(1) value storage
   - Abstract `PrefixIndex` is used provide the optimal performance for user needs

4. **PrefixIndex Protocol** (`Internal/PrefixIndex.swift`)
   - Defines base set-like operations required to manage keys index
   - Not sendable
   - All functions are synchronous
   
5. **RadixTree** (`Internal/RadixTree.swift`)
   - Radix Trie implementation for prefix search
   - Compresses single-child chains for memory efficiency
   - Supports unicode and special characters in keys

6. **SetIndex** (`Internal/SetIndex.swift`)
   - A simple reference implementation of index storage to benchmarked against

### Data Flow

```
User Code
    ↓
KeyValueStorage Protocol
    ↓
InMemoryStorage Actor ←→ RadixTree
    ↓                       ↓
Dictionary             Prefix Index
(Value Storage)     (Key Organization)
```

## Design Decisions

##### Why Tuist
   - Project management convenience: Allows to keep project settings human readable

##### Why Index is not thread safe

- Performance: Reduces overhead on context switches and locking
- Simpler Implementation: Allows to avoid custom lock managements or handling actor reentrancy
- Access level: Implementation is internal to framework, so if properly handled at KeyValueStorage level, no risk of exposure non-thread safe api to customer


##### Why Radix Tree?

- Fast Prefix Search: O(k + m) vs O(n) linear scan (k - max key length, m - number of matches, n - number of entries in storage)
- Memory Efficient: Compresses single-child chains unlike standard tries

##### Why Actors Instead of Locks?

- Compiler-Verified Safety: Swift 6 strict concurrency catches data races at compile time
- Simpler Code: No manual lock management


## Performance Notes and potential improvements

Current implementation has several significant drawbacks due to assignment deadlines

##### `getRandomValue` method is not possible to implement with current signature for potential persistent storage

For in memory storage this signature works since all types are preserved while app is running, but for persistent mode this claim is not held, and since swift is a statically typed language, we need some way to provide type stored value is deserialized to at compile time.
But introducing `getRandomValue<T>(as type: T.Type) async -> T?` signature introduces another dilemma: do we run random over all key-value pairs or only over ones for which value type matches the requested one? 
In first case it leads to the unobvious behavior: function could return nil even for non-empty storage. In second one it significantly affects implementation complexity, requiring storing separate index for each value type.

So, current decision is to keep in-memory only compatible signature.

##### Non-optimal Radix Tree implementation

Current Radix Tree implementation is far from optimal for several reasons:

##### Non-optimal strings engine

Implementation uses default swift strings with unicode-based indexing, uses expensive hasPrefix, commonPrefix operations, even `.count` calculation is O(n) for unicode strings. Also every slice-to-string convert triggers a lot of heap-heavy copying.

**Solution**: 
- Use byte arrays instead of strings for key management

##### Dictionaries for branches storage

Though storing children using dictionary looks quite natural, it introducing a lot of overhead for hashes calculation, eventual dictionary rebalance etc

**Solution**: 
- Use inline arrays + dynamic nodes resizing (Node4 -> Node8 -> Node16) etc instead of dictionaries for children and branch label storage


##### Index updates slow down put/delete operation

The InMemoryStorage actor holds both:
  - storage: [String: any Sendable] - O(1) dictionary operations
  - prefixIndex: PrefixIndex - O(k) RadixTree operations

The actor provides a single implicit lock that serializes all operations. When put() or delete() runs, the entire O(k) index update blocks all other operations including simple get() calls.

**Solution**:
    - separate locking mechanisms for storage and index
    - add a queue for index operations.

## Benchmark

**Test environment:**
- Host: Apple Silicon (arm64), 8 processors, 16 GB memory
- OS: Darwin Kernel Version 25.1.0

### Insert

Time to insert N key-value pairs into the storage.

| Sample Size | Radix (ms) | Set (ms) |
|-------------|------------|----------|
| 1,000       | 13         | 0        |
| 10,000      | 157        | 4        |
| 100,000     | 1,858      | 47       |
| 1,000,000   | 21,380     | 579      |

### Get by Key

Time to retrieve N values by their exact keys. Single implementation only since index is not used.

| Sample Size | Any (ms)   |
|-------------|------------|
| 1,000       | 0          |
| 10,000      | 2          |
| 100,000     | 20         |
| 1,000,000   | 240        |

### Get Random

Time to perform N random key lookups.

| Sample Size | Radix (ms) | Set (ms)    |
|-------------|------------|-------------|
| 1,000       | 1          | 2           |
| 10,000      | 9          | 163         |
| 100,000     | 157        | 15,332      |
| 1,000,000   | 2,597      | 1,525,368   |

### Keys by Prefix

Time to retrieve all keys matching a prefix (N iterations).

| Sample Size | Radix (ms) | Set (ms) |
|-------------|------------|----------|
| 1,000       | 13         | 11       |
| 10,000      | 41         | 108      |
| 100,000     | 345        | 1,204    |
| 1,000,000   | 2,972      | 15,019   |

### Memory (Resident Peak)

Peak memory usage per number of keys. Keys are random. Key length uniformly distributed between 3 and 900 bytes. Same set of keys used for both implementations

| Sample Size | Radix (MB) | Set (MB) |
|-------------|------------|----------|
| 1,000       | 193        | 192      |
| 10,000      | 198        | 195      |
| 100,000     | 233        | 210      |
| 1,000,000   | 579        | 344      |
