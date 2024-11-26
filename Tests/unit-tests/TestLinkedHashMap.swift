import SwiftLinkedListAndHash
import Testing

class TestLinkedHashMap {
    @Test func addLookupDel() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var map = LinkedHashMap<ValueNode>(1)
        _ = add(&map)

        let expect1 = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(expect1.data == 0xf123_e456_d789_cbaf)
        let expect2 = map[Key(a: 0xf123_4566, b: 0xf122)]!
        #expect(expect2.data == 0xf123_e456_d789_cbae)
        let expectNil = map[Key(a: 1, b: 2)]
        #expect(expectNil == nil)

        #expect(testLinkedListDeinitCount == 0)
    }

    @Test func addThenDel() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var map = LinkedHashMap<ValueNode>(1)
        addAndDel(&map)

        let expect1Nil = map[Key(a: 0xf123_4567, b: 0xf123)]
        #expect(expect1Nil == nil)

        #expect(testLinkedListDeinitCount == 1)
    }

    @Test func destroy() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var map = LinkedHashMap<ValueNode>(1)
        _ = add(&map)
        map.destroy()

        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func addSame() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }

        var map = LinkedHashMap<ValueNode>(1)
        let (e1, _) = add(&map)
        var res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 0xf123_e456_d789_cbaf)

        let e = Value(key: Key(a: 0xf123_4567, b: 0xf123), data: 111)
        e.node.addInto(map: &map)

        res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 0xf123_e456_d789_cbaf)

        e1.node.removeSelf()
        res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 111)
    }

    @Test func insertSame() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }

        var map = LinkedHashMap<ValueNode>(1)
        _ = add(&map)
        var res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 0xf123_e456_d789_cbaf)

        let e = Value(key: Key(a: 0xf123_4567, b: 0xf123), data: 111)
        e.node.insertInto(map: &map)

        res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 111)

        e.node.removeSelf()
        res = map[Key(a: 0xf123_4567, b: 0xf123)]!
        #expect(res.data == 0xf123_e456_d789_cbaf)
    }

    @Test func refAndDeinit() { // might crash after calling .destroy() if the map is using ~Copyable
        _ = MapHolder(1024)
    }

    private func add(_ map: inout LinkedHashMap<ValueNode>) -> (Value, Value) {
        let value1 = Value(key: Key(a: 0xf123_4567, b: 0xf123), data: 0xf123_e456_d789_cbaf)
        let value2 = Value(key: Key(a: 0xf123_4566, b: 0xf122), data: 0xf123_e456_d789_cbae)
        value1.node.addInto(map: &map)
        value2.node.addInto(map: &map)
        return (value1, value2)
    }

    private func addAndDel(_ map: inout LinkedHashMap<ValueNode>) {
        let (v1, _) = add(&map)
        v1.node.removeSelf()
    }
}

class MapHolder {
    var map: LinkedHashMap<ValueNode>
    init(_ n: Int) {
        map = .init(n)
    }

    deinit {
        map.destroy()
    }
}

struct Key: Hashable {
    var a: UInt32
    var b: UInt16
}

class Value {
    var node = ValueNode()
    var key: Key
    var data: UInt64

    init(key: Key, data: UInt64) {
        self.key = key
        self.data = data
    }

    deinit {
        testLinkedListDeinitCount += 1
    }
}

struct ValueNode: LinkedHashMapEntry {
    typealias K = Key
    typealias V = Value

    var vars = LinkedListNodeVars()

    mutating func key() -> Key {
        return element().key
    }

    static let fieldOffset = 0
}
