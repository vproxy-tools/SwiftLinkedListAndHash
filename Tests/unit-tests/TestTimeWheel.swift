import SwiftLinkedListAndHash
import Testing

class TestTimeWheel {
    @Test func simple() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: w)

        let next = w.nextTimeAccurate()
        #expect(next == 110_000)

        var ret = w.poll(currentTimeMillis: 105_000)
        #expect(ret.list.first() == nil)

        ret = w.poll(currentTimeMillis: 110_000)
        #expect(ret.list.first() === elem1)

        ret = w.poll(currentTimeMillis: 110_000)
        #expect(ret.list.first() == nil)
    }

    @Test func withinThisTick() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 100_010
        _ = elem1.node.addInto(wheel: w)

        var ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.list.first() === elem1)

        ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.list.first() == nil)
    }

    @Test func inThePast() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 90000
        _ = elem1.node.addInto(wheel: w)

        let next = w.nextTimeAccurate()
        #expect(next == 100_000)

        var ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.list.first() === elem1)

        ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.list.first() == nil)
    }

    @Test func multipleInOneTick() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: w)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 110_050
        _ = elem2.node.addInto(wheel: w)

        let ret = w.poll(currentTimeMillis: 110_000)

        var lastIndex = -1
        for (i, e) in ret.list.seq().enumerated() {
            if i == 0 {
                #expect(e === elem1)
            } else {
                #expect(e === elem2)
            }
            lastIndex = i
        }
        #expect(lastIndex == 1)
    }

    @Test func twoTicksTwoPoll() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: w)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 120_000
        _ = elem2.node.addInto(wheel: w)

        var ret = w.poll(currentTimeMillis: 115_000)
        #expect(ret.list.first() === elem1)

        ret = w.poll(currentTimeMillis: 120_000)
        #expect(ret.list.first() === elem2)
    }

    @Test func multipleTicksOnePoll() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: w)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 120_000
        _ = elem2.node.addInto(wheel: w)

        let ret = w.poll(currentTimeMillis: 120_000)

        var lastIndex = -1
        for (i, e) in ret.list.seq().enumerated() {
            if i == 0 {
                #expect(e === elem1)
            } else {
                #expect(e === elem2)
            }
            lastIndex = i
        }
        #expect(lastIndex == 1)
    }

    @Test func expand() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: w)

        var next = w.nextTimeAccurate()
        #expect(next == 175_000)

        var ret = w.poll(currentTimeMillis: 160_000)
        #expect(ret.list.first() == nil)

        next = w.nextTimeAccurate()
        #expect(next == 175_000)

        ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.list.first() === elem1)
    }

    @Test func returnOnExpand() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: w)

        let ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.list.first() === elem1)
    }

    @Test func expandReturnAndFillTicks() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: w)
        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 178_000
        _ = elem2.node.addInto(wheel: w)

        var ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.list.first() === elem1)
        ret = w.poll(currentTimeMillis: 179_000)
        #expect(ret.list.first() === elem2)
    }

    @Test func expandThroughMultipleLevels() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 100_000 + 1000 * 60 * 60 * 5 // 5 hours later
        _ = elem1.node.addInto(wheel: w)

        let ret = w.poll(currentTimeMillis: 100_000 + 1000 * 60 * 60 * 5)
        #expect(ret.list.first() === elem1)
    }

    @Test func addUnableToFillElem() {
        let w = TimeWheel<TimeElemNode>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 1000 * 60 * 60 * 24 + 1 // more than 24 hours
        let succeeded = elem1.node.addInto(wheel: w)
        #expect(!succeeded)
    }
}

class TimeElem {
    var node = TimeElemNode()
    let n: Int

    init(_ n: Int) {
        self.n = n
    }
}

struct TimeElemNode: TimeNode {
    typealias V = TimeElem

    var vars = LinkedListNodeVars()
    var triggerTime: Int64 = 0
    static let fieldOffset: Int = 0

    init() {}
}
