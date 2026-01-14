import Testing
@testable import KeyValueStorage

extension RadixTree.Node {
    func dump() -> String {
        return "\(subtreeKeyCount): " + children.keys.sorted().map {
            "\($0)->[\(children[$0]!.dump())]"
        }.joined(separator: ",")
    }
}

extension RadixTree {
    func dump() -> String {
        return "[\(root.dump())]"
    }
}

// NOTE: performance test makes sence to implement on the whole dictionary
@Suite
struct RadixTreeTests {
    @Suite
    struct BasicFunctions {
        @Test("Correctly inserts values")
        func insertAndContains() async {
            let tree = RadixTree()

             tree.insert("tokyo")

            #expect( tree.contains("tokyo"))
            #expect( tree.contains("tokyo:population") == false)
            #expect( tree.contains("tok") == false)
        }

        @Test("Insert multiple keys")
        func insertMultipleKeys() async {
            let tree = RadixTree()

             tree.insert("tokyo")
             tree.insert("toronto")
             tree.insert("paris")
             tree.insert("prague")

            #expect( tree.contains("tokyo"))
            #expect( tree.contains("toronto"))
            #expect( tree.contains("paris"))
            #expect( tree.contains("prague"))
        }

        @Test("Keys with prefix")
        func keysWithPrefix() async {
            let tree = RadixTree()

             tree.insert("city:tokyo:population")
             tree.insert("city:tokyo:latitude")
             tree.insert("city:toronto:population")
             tree.insert("country:japan:name")
             tree.insert("country:japan:capital")

            let tokyoKeys =  tree.keysWithPrefix("city:tokyo").sorted()
            #expect(tokyoKeys == ["city:tokyo:latitude", "city:tokyo:population"])

            let countryKeys =  tree.keysWithPrefix("country:japan").sorted()
            #expect(countryKeys == ["country:japan:capital", "country:japan:name"])

            let cityKeys =  tree.keysWithPrefix("city:to").sorted()
            #expect(cityKeys == ["city:tokyo:latitude", "city:tokyo:population", "city:toronto:population"])
        }

        @Test("Keys with empty prefix")
        func keysWithEmptyPrefix() async {
            let tree = RadixTree()

             tree.insert("amsterdam")
             tree.insert("berlin")
             tree.insert("cairo")

            let allKeys =  tree.keysWithPrefix("").sorted()
            #expect(allKeys == ["amsterdam", "berlin", "cairo"])
        }

        @Test("Keys with prefix no matches")
        func keysWithPrefixNoMatches() async {
            let tree = RadixTree()

             tree.insert("amsterdam")
             tree.insert("berlin")

            let keys =  tree.keysWithPrefix("cairo")
            #expect(keys.isEmpty)
        }

        @Test("Remove key")
        func remove() async {
            let tree = RadixTree()

             tree.insert("tokyo")
             tree.insert("tokyo:population")
             tree.insert("toronto")

            let containsBefore =  tree.contains("tokyo")
            #expect(containsBefore)

             tree.remove("tokyo")

            #expect( tree.contains("tokyo") == false)
            #expect( tree.contains("tokyo:population"))
            #expect( tree.contains("toronto"))
        }

        @Test("Remove non-existent key")
        func removeNonExistent() async {
            let tree = RadixTree()

             tree.insert("tokyo")

            #expect( tree.contains("tokyo"))
        }

        @Test("Remove all keys")
        func removeAll() async {
            let tree = RadixTree()

             tree.insert("amsterdam")
             tree.insert("berlin")
             tree.insert("cairo")

             tree.removeAll()

            #expect( tree.contains("amsterdam") == false)
            #expect( tree.contains("berlin") == false)
            #expect( tree.contains("cairo") == false)
            #expect( tree.keysWithPrefix("").isEmpty)
        }

        @Test("Empty tree operations")
        func emptyTree() async {
            let tree = RadixTree()

            #expect( tree.contains("tokyo") == false)
            #expect( tree.keysWithPrefix("").isEmpty)
            #expect( tree.keysWithPrefix("tokyo").isEmpty)
        }

        @Test("Unicode keys")
        func unicodeKeys() async {
            let tree = RadixTree()

             tree.insert("москва")
             tree.insert("москва:население")
             tree.insert("париж")

            #expect( tree.contains("москва"))
            #expect( tree.contains("париж"))

            let keys =  tree.keysWithPrefix("моск").sorted()
            #expect(keys == ["москва", "москва:население"])
        }

        @Test("Special characters in keys")
        func specialCharacters() async {
            let tree = RadixTree()

             tree.insert("geo@40.7128,-74.0060")
             tree.insert("geo@51.5074,-0.1278")
             tree.insert("location#tokyo")

            #expect( tree.contains("geo@40.7128,-74.0060"))

            let geoKeys =  tree.keysWithPrefix("geo@").sorted()
            #expect(geoKeys == ["geo@40.7128,-74.0060", "geo@51.5074,-0.1278"])
        }
    }

    @Suite
    struct TreeStructure {
        @Test("Empty tree is empty")
        func empty() async throws {
            let tree = RadixTree()

            #expect(tree.dump() == "[0: ]")
        }

        @Test("Tree with one key contains one extra node")
        func singleKey() async throws {
            let tree = RadixTree()
             tree.insert("tokyo")

            #expect(tree.dump() == "[1: tokyo->[1: ]]")
        }

        @Test("Tree with keys without shared prefixes")
        func noSharedPrefixes() async throws {
            let tree = RadixTree()
             tree.insert("toronto")
             tree.insert("london")

            #expect(tree.dump() == "[2: london->[1: ],toronto->[1: ]]")
        }

        @Test("Keys with shared prefixes causes edges to split")
        func sharedPrefixes() async throws {
            let tree = RadixTree()
             tree.insert("toronto")
             tree.insert("tokyo")
             tree.insert("london")

            #expect(tree.dump() == "[3: london->[1: ],to->[2: kyo->[1: ],ronto->[1: ]]]")
        }

        @Test("Tree with keys that contain one another")
        func containingKeys() async throws {
            let tree = RadixTree()
             tree.insert("toronto")
             tree.insert("toron")

            #expect(tree.dump() == "[2: toron->[2: to->[1: ]]]")
        }

        @Test("Delete compresses nodes")
        func nodeCompressOnDelete() async throws {
            let tree = RadixTree()
             tree.insert("toronto")
             tree.insert("tokyo")
             tree.insert("london")
             tree.remove("toronto")

            #expect(tree.dump() == "[2: london->[1: ],tokyo->[1: ]]")
        }

        @Test("Repeated insert does not affect the tree")
        func repeatingInsert() async throws {
            let tree = RadixTree()
            tree.insert("toronto")
            tree.insert("tokyo")
            tree.insert("london")
            tree.insert("toronto")

            #expect(tree.dump() == "[3: london->[1: ],to->[2: kyo->[1: ],ronto->[1: ]]]")
        }
    }
}
