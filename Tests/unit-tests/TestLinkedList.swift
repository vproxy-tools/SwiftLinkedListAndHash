import Foundation
import SwiftLinkedListAndHash
import Testing

class TestLinkedList {
    @Test func listAddGet() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var ls1 = LinkedList<ElemNode1>()
        var ls2 = LinkedList<ElemNode2>()
        ls1.selfInit()
        ls2.selfInit()

        _ = addNodes(&ls1, &ls2)

        var e = ls1.first()!
        #expect(e.a == 0xf123)
        #expect(e.b == 0xe456_f789)
        #expect(e.c == 0xd012)
        #expect(e.d == 0xfe_dcba_0fed_cba0)

        e = e.node1.next(list: &ls1)!
        #expect(e.a == 0xf122)
        #expect(e.b == 0xe456_f788)
        #expect(e.c == 0xd011)
        #expect(e.d == 0xfe_dcba_0fed_cba1)

        e = e.node1.next(list: &ls1)!
        #expect(e.a == 0xf121)
        #expect(e.b == 0xe456_f787)
        #expect(e.c == 0xd010)
        #expect(e.d == 0xfe_dcba_0fed_cba2)

        #expect(e.node1.next(list: &ls1) == nil)

        e = ls2.first()!
        #expect(e.a == 0xf123)
        #expect(e.b == 0xe456_f789)
        #expect(e.c == 0xd012)
        #expect(e.d == 0xfe_dcba_0fed_cba0)

        e = e.node2.next(list: &ls2)!
        #expect(e.a == 0xf122)
        #expect(e.b == 0xe456_f788)
        #expect(e.c == 0xd011)
        #expect(e.d == 0xfe_dcba_0fed_cba1)

        e = e.node2.next(list: &ls2)!
        #expect(e.a == 0xf120)
        #expect(e.b == 0xe456_f786)
        #expect(e.c == 0xd009)
        #expect(e.d == 0xfe_dcba_0fed_cba3)

        #expect(e.node1.next(list: &ls1) == nil)
        #expect(testLinkedListDeinitCount == 0)
    }

    @Test func seq() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var ls1 = LinkedList<ElemNode1>()
        var ls2 = LinkedList<ElemNode2>()
        ls1.selfInit()
        ls2.selfInit()

        _ = addNodes(&ls1, &ls2)

        var lastIndex = 0
        for (idx, e) in ls1.seq().enumerated() {
            if idx == 0 {
                #expect(e.a == 0xf123)
                #expect(e.b == 0xe456_f789)
                #expect(e.c == 0xd012)
                #expect(e.d == 0xfe_dcba_0fed_cba0)
            } else if idx == 1 {
                #expect(e.a == 0xf122)
                #expect(e.b == 0xe456_f788)
                #expect(e.c == 0xd011)
                #expect(e.d == 0xfe_dcba_0fed_cba1)
            } else {
                #expect(e.a == 0xf121)
                #expect(e.b == 0xe456_f787)
                #expect(e.c == 0xd010)
                #expect(e.d == 0xfe_dcba_0fed_cba2)
            }
            lastIndex = idx
        }
        #expect(lastIndex == 2)

        lastIndex = 0
        for (idx, e) in ls2.seq().enumerated() {
            if idx == 0 {
                #expect(e.a == 0xf123)
                #expect(e.b == 0xe456_f789)
                #expect(e.c == 0xd012)
                #expect(e.d == 0xfe_dcba_0fed_cba0)
            } else if idx == 1 {
                #expect(e.a == 0xf122)
                #expect(e.b == 0xe456_f788)
                #expect(e.c == 0xd011)
                #expect(e.d == 0xfe_dcba_0fed_cba1)
            } else {
                #expect(e.a == 0xf120)
                #expect(e.b == 0xe456_f786)
                #expect(e.c == 0xd009)
                #expect(e.d == 0xfe_dcba_0fed_cba3)
            }
            lastIndex = idx
        }
        #expect(lastIndex == 2)

        #expect(testLinkedListDeinitCount == 0)
    }

    @Test func del() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var ls1 = LinkedList<ElemNode1>()
        var ls2 = LinkedList<ElemNode2>()
        ls1.selfInit()
        ls2.selfInit()

        addAndRemove(&ls1, &ls2)

        var lastIndex = 0
        for (idx, e) in ls1.seq().enumerated() {
            if idx == 0 {
                #expect(e.a == 0xf123)
                #expect(e.b == 0xe456_f789)
                #expect(e.c == 0xd012)
                #expect(e.d == 0xfe_dcba_0fed_cba0)
            } else {
                #expect(e.a == 0xf121)
                #expect(e.b == 0xe456_f787)
                #expect(e.c == 0xd010)
                #expect(e.d == 0xfe_dcba_0fed_cba2)
            }
            lastIndex = idx
        }
        #expect(lastIndex == 1)

        lastIndex = -1
        for (idx, e) in ls2.seq().enumerated() {
            #expect(e.a == 0xf123)
            #expect(e.b == 0xe456_f789)
            #expect(e.c == 0xd012)
            #expect(e.d == 0xfe_dcba_0fed_cba0)
            lastIndex = idx
        }
        #expect(lastIndex == 0)
        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func destroy() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var ls1 = LinkedList<ElemNode1>()
        var ls2 = LinkedList<ElemNode2>()
        ls1.selfInit()
        ls2.selfInit()

        _ = addNodes(&ls1, &ls2)

        ls1.destroy()
        #expect(testLinkedListDeinitCount == 1) // e3
        ls2.destroy()
        #expect(testLinkedListDeinitCount == 4) // all
    }

    @Test func addBefore() {
        var ls = LinkedList<ElemNode1>()
        var tmp = LinkedList<ElemNode2>()
        ls.selfInit()
        tmp.selfInit()
        _ = addNodes(&ls, &tmp)
        var first = ls.first()!
        #expect(first.a == 0xf123)

        let e = Elem(a: 1, b: 2, c: 3, d: 4)
        e.node1.insertInto(list: &ls)
        first = ls.first()!
        #expect(first.a == 1)
    }

    @Test func addWhenIterating() {
        var ls = LinkedList<ElemNode1>()
        var tmp = LinkedList<ElemNode2>()
        ls.selfInit()
        tmp.selfInit()
        _ = addNodes(&ls, &tmp)

        for e in ls.seq() {
            if e.a == 0xf122 {
                let prev = Elem(a: 1, b: 2, c: 3, d: 4)
                prev.node1.add(before: e)
                let next = Elem(a: 9, b: 8, c: 7, d: 6)
                next.node1.add(after: e)
                ENSURE_REFERENCE_COUNTED(prev, next)
                break
            }
        }

        var e = ls.first()!
        #expect(e.a == 0xf123)
        e = e.node1.next(list: &ls)!
        #expect(e.a == 1)
        e = e.node1.next(list: &ls)!
        #expect(e.a == 0xf122)
        e = e.node1.next(list: &ls)!
        #expect(e.a == 9)
    }

    private func addNodes(_ head1: inout LinkedList<ElemNode1>, _ head2: inout LinkedList<ElemNode2>) -> (Elem, Elem, Elem, Elem) {
        let e1 = Elem(a: 0xf123, b: 0xe456_f789, c: 0xd012, d: 0xfe_dcba_0fed_cba0)
        let e2 = Elem(a: 0xf122, b: 0xe456_f788, c: 0xd011, d: 0xfe_dcba_0fed_cba1)
        let e3 = Elem(a: 0xf121, b: 0xe456_f787, c: 0xd010, d: 0xfe_dcba_0fed_cba2)
        let e4 = Elem(a: 0xf120, b: 0xe456_f786, c: 0xd009, d: 0xfe_dcba_0fed_cba3)

        e1.node1.addInto(list: &head1)
        e2.node1.addInto(list: &head1)
        e3.node1.addInto(list: &head1)

        e1.node2.addInto(list: &head2)
        e2.node2.addInto(list: &head2)
        e4.node2.addInto(list: &head2)

        return (e1, e2, e3, e4)
    }

    private func addAndRemove(_ head1: inout LinkedList<ElemNode1>, _ head2: inout LinkedList<ElemNode2>) {
        let (_, e2, _, e4) = addNodes(&head1, &head2)
        e2.node1.removeSelf()
        e2.node2.removeSelf()
        e4.node2.removeSelf()
    }
}

nonisolated(unsafe) var testLinkedListNoConcurrency = NSLock()
nonisolated(unsafe) var testLinkedListDeinitCount = 0

class Elem {
    var node1 = ElemNode1()
    var node2 = ElemNode2()
    var a: UInt16
    var b: UInt32
    var c: UInt16
    var d: UInt64
    init(a: UInt16, b: UInt32, c: UInt16, d: UInt64) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }

    deinit {
        testLinkedListDeinitCount += 1
    }
}

struct ElemNode1: LinkedListNode {
    typealias V = Elem

    var vars = LinkedListNodeVars()

    static let fieldOffset = 0
}

struct ElemNode2: LinkedListNode {
    typealias V = Elem

    var vars = LinkedListNodeVars()

    static let fieldOffset = 16
}
