import SwiftLinkedListAndHash
import Testing

class TestTimeWheel {
    @Test func simple() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[10].pointee.count == 1)

        let next = w.nextTimeAccurate()
        #expect(next == 110_000)

        var ret = w.poll(currentTimeMillis: 105_000)
        #expect(ret.pointee.first() == nil)

        ret = w.poll(currentTimeMillis: 110_000)
        #expect(ret.pointee.first() === elem1)

        ret = w.poll(currentTimeMillis: 110_000)
        #expect(ret.pointee.first() == nil)
    }

    @Test func withinThisTick() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 100_010
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[0].pointee.count == 1)

        var ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.pointee.first() === elem1)

        ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.pointee.first() == nil)
    }

    @Test func inThePast() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 90_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[0].pointee.count == 1)

        let next = w.nextTimeAccurate()
        #expect(next == 100_000)

        var ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.pointee.first() === elem1)

        ret = w.poll(currentTimeMillis: 100_000)
        #expect(ret.pointee.first() == nil)
    }

    @Test func multipleInOneTick() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[10].pointee.count == 1)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 110_050
        _ = elem2.node.addInto(wheel: &w)
        #expect(w[0].pointee[10].pointee.count == 2)

        let ret = w.poll(currentTimeMillis: 110_000)

        var lastIndex = -1
        for (i, e) in ret.pointee.seq().enumerated() {
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
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[10].pointee.count == 1)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 120_000
        _ = elem2.node.addInto(wheel: &w)
        #expect(w[0].pointee[20].pointee.count == 1)

        var ret = w.poll(currentTimeMillis: 115_000)
        #expect(ret.pointee.first() === elem1)

        ret = w.poll(currentTimeMillis: 120_000)
        #expect(ret.pointee.first() === elem2)
    }

    @Test func multipleTicksOnePoll() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 110_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[0].pointee[10].pointee.count == 1)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 120_000
        _ = elem2.node.addInto(wheel: &w)
        #expect(w[0].pointee[20].pointee.count == 1)

        let ret = w.poll(currentTimeMillis: 120_000)

        var lastIndex = -1
        for (i, e) in ret.pointee.seq().enumerated() {
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
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[1].pointee[1].pointee.count == 1)

        var next = w.nextTimeAccurate()
        #expect(next == 175_000)

        var ret = w.poll(currentTimeMillis: 160_000)
        #expect(ret.pointee.first() == nil)

        next = w.nextTimeAccurate()
        #expect(next == 175_000)

        ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.pointee.first() === elem1)
    }

    @Test func returnOnExpand() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[1].pointee[1].pointee.count == 1)

        let ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.pointee.first() === elem1)
    }

    @Test func expandReturnAndFillTicks() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 175_000
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[1].pointee[1].pointee.count == 1)

        let elem2 = TimeElem(2)
        elem2.node.triggerTime = 178_000
        _ = elem2.node.addInto(wheel: &w)
        #expect(w[1].pointee[1].pointee.count == 2)

        var ret = w.poll(currentTimeMillis: 175_000)
        #expect(ret.pointee.first() === elem1)
        #expect(w[0].pointee[18].pointee.count == 1)

        ret = w.poll(currentTimeMillis: 179_000)
        #expect(ret.pointee.first() === elem2)
    }

    @Test func expandThroughMultipleLevels() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 100_000, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 100_000 + 1000 * 60 * 60 * 5 // 5 hours later
        _ = elem1.node.addInto(wheel: &w)
        #expect(w[2].pointee[5].pointee.count == 1)

        let ret = w.poll(currentTimeMillis: 100_000 + 1000 * 60 * 60 * 5)
        #expect(ret.pointee.first() === elem1)
    }

    @Test func expandThroughMultipleLevelsWithoutTriggerring() {
        let w = TimeWheelRef<TimeElemNode>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 1000 * (3600 + 1) // 1h1s
        _ = elem1.node.addInto(wheel: w)
        #expect(w.pointee[2].pointee[1].pointee.count == 1)
        #expect(w.pointee[0].pointee[1].pointee.count == 0)

        let res = w.poll(currentTimeMillis: 1000 * 3600)
        #expect(res.count == 0)

        let count = w.pointee[0].pointee[1].pointee.count
        #expect(count == 1)
    }

    @Test func addUnableToFillElem() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 1000 * 60 * 60 * 24 + 1 // more than 24 hours
        let succeeded = elem1.node.addInto(wheel: &w)
        #expect(!succeeded)
    }

    @Test func wrapLastLevel() {
        var w = TimeWheel<TimeElemNode>(currentTimeMillis: 0, precisionMillis: 1000, levelTicks: 60, 60, 24)
        let _ = w.poll(currentTimeMillis: 1000 * 60 * 60 * 12)

        let elem1 = TimeElem(1)
        elem1.node.triggerTime = 1000 * 60 * 60 * (12 + 13)

        let ok = elem1.node.addInto(wheel: &w)
        #expect(ok)

        #expect(w[2].pointee[1].pointee.count == 1)

        let res = w.poll(currentTimeMillis: 1000 * 60 * 60 * (12 + 13))
        #expect(res.count == 1)
        for e in res.seq() {
            #expect(e === elem1)
        }
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
