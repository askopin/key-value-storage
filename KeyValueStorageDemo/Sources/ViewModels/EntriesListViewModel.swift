import SwiftUI
import KeyValueStorage

@MainActor
@Observable
final class EntriesListViewModel {
    @ObservationIgnored
    private let storage: KeyValueStorage

    var entries: [StorageEntry] = []
    var searchPrefix: String = ""
    var filteredKeys: [String] = []
    var randomValue: String = ""
    var errorMessage: String = ""

    init() {
        self.storage = StorageProvider.storage(configuration: .inMemory(maxKeySize: 10))
    }

    func addEntry(key: String, value: String) async {
        do {
            try await storage.put(value, forKey: key)
            await refresh()
            errorMessage = ""
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    func deleteEntry(key: String) async {
        await storage.delete(forKey: key)
        await refresh()
    }

    func searchKeys() async {
        filteredKeys = await storage.keys(withPrefix: searchPrefix)
    }

    func getRandomValue() async {
        if let value: String = await storage.getRandomValue() as? String {
            randomValue = value
        } else {
            randomValue = "No values"
        }
    }

    func refresh() async {
        let keys = await storage.allKeys
        var newEntries: [StorageEntry] = []

        for key in keys {
            if let value: String = await storage.get(forKey: key) {
                newEntries.append(StorageEntry(id: key, value: value))
            }
        }

        entries = newEntries
    }

    func clearAll() async {
        await storage.clear()
        await refresh()
    }
}

struct StorageEntry: Identifiable {
    let id: String
    let value: String
}
