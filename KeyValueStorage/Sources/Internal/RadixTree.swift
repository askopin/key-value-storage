import Foundation

/// A Radix Tree (Patricia Trie) data structure for efficient prefix-based key lookup.
/// https://cglab.ca/~morin/teaching/5408/notes/strings.pdf
///
/// ## Complexity
/// - Insert: O(k) where k is the key length
/// - Remove: O(k) where k is the key length
/// - Contains: O(k) where k is the key length
/// - Keys with prefix: O(k + m) where k is prefix length, m is number of matches
/// - Get random O(k) where k is the key length
class RadixTree: PrefixIndex {

    // NOTE: Implementation is very crude and doesn't match theoretical complexity
    // Since some assumptions about operations to be executed as O(1) are not correct
    // Potential inspiration for optimization: https://db.in.tum.de/~leis/papers/ART.pdf
    //  - Inline arrays instead of dict
    //  - Use byte representation of strings to make count comparison O(1) or store edge length

    final class Node {
        var children: [String: Node]
        var isEndOfWord: Bool
        var subtreeKeyCount: Int

        init() {
            self.children = [:]
            self.isEndOfWord = false
            self.subtreeKeyCount = 0
        }
    }

    let root: Node

    init() {
        self.root = Node()
    }

    func insert(_ key: String) {
        guard !key.isEmpty else { return }

        var current = root
        var remainingKey = key
        var keyAlreadyExists = false
        var path: [Node] = [root]
        defer {
            if !keyAlreadyExists {
                for node in path {
                    node.subtreeKeyCount += 1
                }
            }
        }

        while !remainingKey.isEmpty {
            let (matchNode, nonMatchedRemain) = insert(key: remainingKey, at: current)
            guard let matchNode else {
                let leaf = Node()
                leaf.isEndOfWord = true
                leaf.subtreeKeyCount = 1
                current.children[remainingKey] = leaf
                return
            }

            current = matchNode
            path.append(current)
            remainingKey = nonMatchedRemain
        }

        keyAlreadyExists = current.isEndOfWord
        current.isEndOfWord = true
    }

    func contains(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }

        var current = root
        var remaining = key

        while !remaining.isEmpty {
            var matched = false

            for (edge, child) in current.children {
                if remaining.hasPrefix(edge) {
                    current = child
                    remaining = String(remaining.dropFirst(edge.count))
                    matched = true
                    break
                }
            }

            if !matched {
                return false
            }
        }

        return current.isEndOfWord
    }

    func remove(_ key: String) {
        guard !key.isEmpty else { return }
        removeRecursive(node: root, key: key)
    }

    func keysWithPrefix(_ prefix: String) -> [String] {
        if prefix.isEmpty {
            return collectKeys(from: root, prefix: "")
        }

        var current = root
        var remaining = prefix
        var consumedPrefix = ""

        while !remaining.isEmpty {
            var matched = false

            for (edge, child) in current.children {
                let commonPrefix = remaining.commonPrefix(with: edge)

                if commonPrefix.isEmpty {
                    continue
                }

                if remaining.hasPrefix(edge) && remaining != edge {
                    // Full edge match and something still remains, continue deeper
                    current = child
                    consumedPrefix += edge
                    remaining = String(remaining.dropFirst(edge.count))
                    matched = true
                    break
                } else if edge.hasPrefix(remaining) {
                    // Prefix ends in the middle of an edge
                    // Or full match that consumes all remaining prefix
                    // All keys under this edge match
                    consumedPrefix += edge
                    var results: [String] = []
                    if child.isEndOfWord {
                        results.append(consumedPrefix)
                    }
                    results.append(contentsOf: collectKeys(from: child, prefix: consumedPrefix))
                    return results
                }
            }

            if !matched {
                return []
            }
        }

        return []
    }

    func removeAll() {
        root.children.removeAll()
        root.isEndOfWord = false
        root.subtreeKeyCount = 0
    }

    func randomElement() -> String? {
        guard root.subtreeKeyCount > 0 else { return nil }

        let targetIndex = Int.random(in: 0..<root.subtreeKeyCount)
        return getRandomRecursive(node: root, targetIndex: targetIndex, prefix: "")
    }

    // MARK: - Helper

    // NOTE: for unicode string length calculation is O(n)
    // And conversion of Substring to string causes buffer to be copied
    // There is a lot space for low-level optimizations here

    private func removeCompressingIfNeeded(childOf node: Node, by edge: String) {
        if let childToRemove = node.children[edge],
           childToRemove.children.count == 1,
           let edgeToCompress = childToRemove.children.keys.first {
           node.children[edge + edgeToCompress] = childToRemove.children[edgeToCompress]
        }

        node.children.removeValue(forKey: edge)
    }

    private func insert(key: String, at node: Node) -> (node: Node?, remainingKey: String) {
        for (edge, child) in node.children {
            let commonPrefix = key.commonPrefix(with: edge)
            if commonPrefix.isEmpty {
                continue
            }

            if commonPrefix.count == edge.count {

                return (child, String(key.dropFirst(commonPrefix.count)))
            } else {
                // NOTE: Potentially could be optimized to save one iteration:
                // we already know that remains of the key requires a new node
                // otherwise we had a full match, so we can just add it here
                // But for sake of readibility keeping code shorter
                let remainingKey = String(key.dropFirst(commonPrefix.count))
                let newNode = split(edge: edge, of: node, prefix: commonPrefix)
                return (newNode, remainingKey)
            }
        }

        return (nil, key)
    }

    private func split(edge: String, of node: Node, prefix: String) -> Node {
        // [1] - abc -> [2]
        // transforms into
        // [1] - ab -> [3 (new)] - c -> [2]
        let newNode = Node()
        let child = node.children[edge]
        let remainingEdge = String(edge.dropFirst(prefix.count))

        node.children.removeValue(forKey: edge)
        node.children[prefix] = newNode
        newNode.children[remainingEdge] = child
        newNode.subtreeKeyCount = child?.subtreeKeyCount ?? 0
        return newNode
    }

    private func collectKeys(from node: Node, prefix: String) -> [String] {
        var results: [String] = []
        for (edge, child) in node.children {
            let newPrefix = prefix + edge
            if child.isEndOfWord {
                results.append(newPrefix)
            }
            results += collectKeys(from: child, prefix: newPrefix)
        }

        return results
    }

    @discardableResult
    private func removeRecursive(node: Node, key: String) -> Bool {
        if key.isEmpty {
            if node.isEndOfWord {
                node.isEndOfWord = false
                node.subtreeKeyCount -= 1
                return node.children.isEmpty
            }

            return false
        }

        for (edge, child) in node.children where key.hasPrefix(edge) {
            let remaining = String(key.dropFirst(edge.count))
            let shouldRemoveChild = removeRecursive(node: child, key: remaining)

            if shouldRemoveChild {
                removeCompressingIfNeeded(childOf: node, by: edge)
            }

            node.subtreeKeyCount -= 1
            // if this node has only one child and is not end of word,
            // marking for delete triggering compress
            return !node.isEndOfWord && node.children.count <= 1
        }

        return false
    }

    private func getRandomRecursive(node: Node, targetIndex: Int, prefix: String) -> String? {
        var currentIndex = targetIndex

        if node.isEndOfWord {
            if currentIndex == 0 {
                return prefix
            }
            currentIndex -= 1
        }

        for (edge, child) in node.children {
            if currentIndex < child.subtreeKeyCount {
                return getRandomRecursive(node: child, targetIndex: currentIndex, prefix: prefix + edge)
            }
            currentIndex -= child.subtreeKeyCount
        }

        assertionFailure("This should never happen, non empty tree should always return random element")
        return nil
    }

}
