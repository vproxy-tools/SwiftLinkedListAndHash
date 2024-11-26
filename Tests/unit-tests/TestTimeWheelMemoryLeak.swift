import SwiftLinkedListAndHash
import Testing

class TestTimeWheelMemoryLeak {
    @Test func notPolled() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var w = TimeWheel<TimeElemNodeLeak>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 10, 10, 10)
        addTimeEvents(&w)

        w.destroy()
        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func polled() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var w = TimeWheel<TimeElemNodeLeak>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 10, 10, 10)
        addTimeEvents(&w)

        poll(&w, 2000, expectedCount: 1)

        #expect(testLinkedListDeinitCount == 1)
        w.destroy()
        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func expanded() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var w = TimeWheel<TimeElemNodeLeak>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 10, 10, 10)
        addTimeEvents(&w)

        poll(&w, 20000, expectedCount: 1)
        #expect(testLinkedListDeinitCount == 1)

        w.destroy()
        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func expandedAndAppendedToReturn() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var w = TimeWheel<TimeElemNodeLeak>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 10, 10, 10)
        addTimeEvents(&w)

        poll(&w, 30000, expectedCount: 2)
        #expect(testLinkedListDeinitCount == 2)

        w.destroy()
        #expect(testLinkedListDeinitCount == 2)
    }

    @Test func expandedAndReturn() {
        testLinkedListNoConcurrency.lock()
        defer { testLinkedListNoConcurrency.unlock() }
        testLinkedListDeinitCount = 0

        var w = TimeWheel<TimeElemNodeLeak>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 10, 10, 10)
        addTimeEvents(&w)

        poll(&w, 25000, expectedCount: 2)
        #expect(testLinkedListDeinitCount == 2)

        w.destroy()
        #expect(testLinkedListDeinitCount == 2)
    }

    private func addTimeEvents(_ w: inout TimeWheel<TimeElemNodeLeak>) {
        let elem1 = TimeElemLeak(1)
        elem1.node.triggerTime = 1000
        _ = elem1.node.addInto(wheel: &w)

        let elem2 = TimeElemLeak(2)
        elem2.node.triggerTime = 25000
        _ = elem2.node.addInto(wheel: &w)

        ENSURE_REFERENCE_COUNTED(elem1, elem2)
    }

    private func poll(_ w: inout TimeWheel<TimeElemNodeLeak>, _ curr: Int64, expectedCount: Int) {
        let res = w.poll(currentTimeMillis: curr)
        #expect(res.count == expectedCount)
    }
}

class TimeElemLeak {
    var node = TimeElemNodeLeak()
    var num: Int
    init(_ num: Int) {
        self.num = num
    }

    deinit {
        testLinkedListDeinitCount += 1
    }
}

struct TimeElemNodeLeak: TimeNode {
    static let fieldOffset: Int = 0

    typealias V = TimeElemLeak
    var vars = LinkedListNodeVars()
    var triggerTime: Int64 = 0
    init() {}
}
