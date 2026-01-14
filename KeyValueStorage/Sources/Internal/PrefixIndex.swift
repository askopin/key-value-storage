
protocol PrefixIndex {
    func insert(_ key: String)
    func contains(_ key: String) -> Bool
    func remove(_ key: String)
    func keysWithPrefix(_ prefix: String) -> [String]
    func removeAll()
    func randomElement() -> String?
}

class SetIndex: PrefixIndex {
    var indexSet = Set<String>()

    func insert(_ key: String) {
        indexSet.insert(key)
    }

    func contains(_ key: String) -> Bool {
        indexSet.contains(key)
    }

    func remove(_ key: String) {
        indexSet.remove(key)
    }

    func keysWithPrefix(_ prefix: String) -> [String] {
        indexSet.filter { $0.hasPrefix(prefix) }
    }
    
    func removeAll() {
        indexSet.removeAll()
    }

    func randomElement() -> String?  {
        indexSet.randomElement()
    }
}
