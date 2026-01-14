import XCTest
@testable import KeyValueStorage

final class InMemoryStorageTests: XCTestCase {

    func testPutAndGetString() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("Asia/Tokyo", forKey: "city:tokyo:timezone")

        let timezone: String? = await storage.get(forKey: "city:tokyo:timezone")
        XCTAssertEqual(timezone, "Asia/Tokyo")
    }

    func testPutAndGetBool() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(true, forKey: "city:paris:isCapital")

        let isCapital: Bool? = await storage.get(forKey: "city:paris:isCapital")
        XCTAssertEqual(isCapital, true)
    }

    func testPutAndGetInt() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(9000000, forKey: "city:london:population")

        let population: Int? = await storage.get(forKey: "city:london:population")
        XCTAssertEqual(population, 9000000)
    }

    func testPutAndGetCustomCodableType() async throws {
        struct CityInfo: Sendable, Codable, Equatable {
            let name: String
            let country: String
        }

        let storage = StorageProvider.inMemory()
        let cityInfo = CityInfo(name: "Tokyo", country: "Japan")

        try await storage.put(cityInfo, forKey: "city:tokyo:info")

        let retrieved: CityInfo? = await storage.get(forKey: "city:tokyo:info")
        XCTAssertEqual(retrieved, cityInfo)
    }

    func testOverwriteExistingKey() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("England", forKey: "city:london:country")
        try await storage.put("United Kingdom", forKey: "city:london:country")

        let country: String? = await storage.get(forKey: "city:london:country")
        XCTAssertEqual(country, "United Kingdom")
    }

    func testGetNonExistentKey() async {
        let storage = StorageProvider.inMemory()

        let value: String? = await storage.get(forKey: "NonExistent")
        XCTAssertNil(value)
    }

    func testGetWithTypeMismatch() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("string value", forKey: "TestKey")

        let wrongType: Int? = await storage.get(forKey: "TestKey")
        XCTAssertNil(wrongType)
    }

    func testTypeErasedGet() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("string value", forKey: "TestKey")

        let value = await storage.get(forKey: "TestKey")
        XCTAssert(try XCTUnwrap(value) is String)
    }


    func testPutWithEmptyKeyThrows() async {
        let storage = StorageProvider.inMemory()

        do {
            try await storage.put("value", forKey: "")
            XCTFail("Expected empty key error")
        } catch StorageError.emptyKey {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPutWithOversizedKeyThrows() async {
        let storage = InMemoryStorage(prefixIndex: RadixTree(), maxKeySize: 10)
        let oversizedKey = String(repeating: "a", count: 100) // > 1KB

        do {
            try await storage.put("value", forKey: oversizedKey)
            XCTFail("Expected key too large error")
        } catch StorageError.keyTooLarge {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testKeysExactMatchingLengthLimitWork() async throws {
        let storage = InMemoryStorage(prefixIndex: RadixTree(), maxKeySize: 10)
        let oversizedKey = String(repeating: "a", count: 10) // > 1KB


        try await storage.put("value", forKey: oversizedKey)
    }

    func testDeleteExistingKey() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(true, forKey: "city:berlin:isCapital")
        await storage.delete(forKey: "city:berlin:isCapital")

        let value: Bool? = await storage.get(forKey: "city:berlin:isCapital")
        XCTAssertNil(value)
    }

    func testDeletePreservesOtherKeys() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("France", forKey: "city:paris:country")
        try await storage.put("Europe/Paris", forKey: "city:paris:timezone")

        await storage.delete(forKey: "city:paris:country")

        let country: String? = await storage.get(forKey: "city:paris:country")
        let timezone: String? = await storage.get(forKey: "city:paris:timezone")

        XCTAssertNil(country)
        XCTAssertEqual(timezone, "Europe/Paris")
    }

    func testDeleteNonExistentKey() async {
        let storage = StorageProvider.inMemory()

        await storage.delete(forKey: "NonExistent")
    }

    func testClearRemovesAllKeys() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("Tokyo", forKey: "city:name")
        try await storage.put(true, forKey: "city:isCapital")
        try await storage.put(13960000, forKey: "city:population")

        await storage.clear()

        let name: String? = await storage.get(forKey: "city:name")
        let isCapital: Bool? = await storage.get(forKey: "city:isCapital")
        let population: Int? = await storage.get(forKey: "city:population")
        let count = await storage.count

        XCTAssertNil(name)
        XCTAssertNil(isCapital)
        XCTAssertNil(population)
        XCTAssertEqual(count, 0)
    }

    func testKeysWithPrefixMultipleMatches() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(13960000, forKey: "city:tokyo:population")
        try await storage.put(35.6762, forKey: "city:tokyo:latitude")
        try await storage.put(2241000, forKey: "city:paris:population")

        let tokyoKeys = await storage.keys(withPrefix: "city:tokyo")

        XCTAssertEqual(tokyoKeys.sorted(), ["city:tokyo:latitude", "city:tokyo:population"])
    }

    func testKeysWithPrefixSingleMatch() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("value", forKey: "UniqueKey")

        let keys = await storage.keys(withPrefix: "Unique")

        XCTAssertEqual(keys, ["UniqueKey"])
    }

    func testKeysWithPrefixNoMatches() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("value1", forKey: "Key1")
        try await storage.put("value2", forKey: "Key2")

        let keys = await storage.keys(withPrefix: "NoMatch")

        XCTAssertTrue(keys.isEmpty)
    }

    func testKeysWithEmptyPrefixReturnsAllKeys() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(1, forKey: "Key1")
        try await storage.put(2, forKey: "Key2")
        try await storage.put(3, forKey: "Key3")

        let keys = await storage.keys(withPrefix: "")

        XCTAssertEqual(keys.sorted(), ["Key1", "Key2", "Key3"])
    }

    func testAllKeysProperty() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("a", forKey: "alpha")
        try await storage.put("b", forKey: "beta")

        let allKeys = await storage.allKeys

        XCTAssertEqual(allKeys.sorted(), ["alpha", "beta"])
    }

    func testKeysAreReturnedInAlphabeticalOrder() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put(1, forKey: "city:zurich")
        try await storage.put(2, forKey: "city:amsterdam")
        try await storage.put(3, forKey: "city:milan")

        let keys = await storage.allKeys

        XCTAssertEqual(keys, ["city:amsterdam", "city:milan", "city:zurich"])
    }

    func testGetRandomValueFromMultipleEntries() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("Tokyo", forKey: "city:1")
        try await storage.put("Paris", forKey: "city:2")
        try await storage.put("London", forKey: "city:3")

        let randomValue = await storage.getRandomValue() as? String

        XCTAssertNotNil(randomValue)
        XCTAssertTrue(["Tokyo", "Paris", "London"].contains(randomValue!))
    }

    func testGetRandomValueFromEmptyStorage() async {
        let storage = StorageProvider.inMemory()

        let randomValue = await storage.getRandomValue()

        XCTAssertNil(randomValue)
    }

    func testGetRandomValueFromSingleEntry() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("onlyValue", forKey: "onlyKey")

        let randomValue = await storage.getRandomValue() as? String

        XCTAssertEqual(randomValue, "onlyValue")
    }

    func testCountProperty() async throws {
        let storage = StorageProvider.inMemory()

        let initialCount = await storage.count
        XCTAssertEqual(initialCount, 0)

        try await storage.put("value1", forKey: "key1")
        let afterOne = await storage.count
        XCTAssertEqual(afterOne, 1)

        try await storage.put("value2", forKey: "key2")
        let afterTwo = await storage.count
        XCTAssertEqual(afterTwo, 2)

        await storage.delete(forKey: "key1")
        let afterDelete = await storage.count
        XCTAssertEqual(afterDelete, 1)
    }

    func testConvenienceGetMethod() async throws {
        let storage = StorageProvider.inMemory()

        try await storage.put("test", forKey: "key")

        let value: String? = await storage.get(forKey: "key")
        XCTAssertEqual(value, "test")
    }

    func testConcurrentInsert() async throws {
        let storage = StorageProvider.inMemory()
        let keysToInsert = (0..<100)
            .map { _ in Int.random(in: 1..<1_000_000)}
            .map { String($0) }
        await withThrowingTaskGroup(of: Void.self) { group in
            for key in keysToInsert {
                group.addTask {
                    try await storage.put(Int.random(in: 0..<100), forKey: key)
                }
            }
        }

        for key in keysToInsert {
            let value = await storage.get(forKey: key)
            XCTAssertNotNil(value)
        }
    }

    func testConcurrentGet() async throws {
        let numberOfKeysToFetch = 1000
        let storedValue = 2
        let storage = StorageProvider.inMemory()
        let keysToInsert = (0..<1000)
            .map { _ in Int.random(in: 1..<1_000_000)}
            .map { String($0) }
        for key in keysToInsert {
            try await storage.put(storedValue, forKey: key)
        }

        let sum = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in (0..<numberOfKeysToFetch){
                group.addTask {
                    let value = await storage.getRandomValue()
                    return try XCTUnwrap(value as? Int)
                }
            }

            return try await group.reduce(0, +)
        }

        XCTAssertEqual(sum, numberOfKeysToFetch * storedValue)
    }
}
