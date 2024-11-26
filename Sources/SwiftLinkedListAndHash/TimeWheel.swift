public struct TimeWheel<NODE: TimeNode> {
    @usableFromInline let precisionMillis: Int64
    @usableFromInline var levels: [TimeLevel<NODE>]

    @usableFromInline var lastTs: Int64 = 0

    // for example, .init(precisionMillis: 1000, levelTicks: 60, 60, 24)
    // would create a timewheel for one day
    // to be more precise, safely 23 hours, max 24 hours
    @inlinable @inline(__always)
    public init(currentTimeMillis: Int64, precisionMillis: Int64, levelTicks: Int, _ moreTicks: Int...) {
        self.init(currentTimeMillis: currentTimeMillis, precisionMillis: precisionMillis, levelTicks: levelTicks, moreTicks)
    }

    @usableFromInline
    init(currentTimeMillis: Int64, precisionMillis: Int64, levelTicks: Int, _ moreTicks: [Int]) {
        if currentTimeMillis % precisionMillis == 0 {
            lastTs = currentTimeMillis
        } else {
            lastTs = currentTimeMillis - (currentTimeMillis % precisionMillis)
        }
        self.precisionMillis = precisionMillis
        let totalLevels = 1 + moreTicks.count
        levels = .init(unsafeUninitializedCapacity: totalLevels) { _, sz in sz = totalLevels }
        let u8p: UnsafeMutablePointer<UInt8> = Unsafe.raw2mutptr(levels.withUnsafeBufferPointer { p in p.baseAddress! })
        let memSize = MemoryLayout<TimeLevel<NODE>>.stride
        for i in 0 ..< totalLevels * memSize {
            u8p.advanced(by: i).pointee = 0
        }

        levels[0].selfInit(tickCount: levelTicks)
        for i in 0 ..< moreTicks.count {
            levels[i + 1].selfInit(tickCount: moreTicks[i])
        }
    }

    @inlinable @inline(__always)
    public subscript(_ index: Int) -> UnsafeMutablePointer<TimeLevel<NODE>> {
        @inlinable @inline(__always)
        mutating get {
            Unsafe.addressOf(evenMoreUnsafe: &levels[index])
        }
    }

    @inlinable @inline(__always)
    mutating func add(n: inout NODE) -> Bool {
        if n.triggerTime <= lastTs {
            let p = self[0]
            n.addInto(list: &(p.pointee[p.pointee.curr].pointee))
            return true
        }

        var precision = precisionMillis
        for i in 0 ..< levels.count {
            let p = self[i]
            if p.pointee.maxTime(last: lastTs, precision: precision, isLastLevel: i == levels.count - 1) <= n.triggerTime {
                precision *= Int64(p.pointee.ticks.count)
                continue
            }
            p.pointee.add(last: lastTs, precision: precision, n: &n)
            return true
        }
        return false
    }

    @inlinable @inline(__always)
    public mutating func nextTimeFast() -> Int64 {
        let precision = precisionMillis
        // for the first level:
        let p = self[0]
        for idx in p.pointee.curr ..< p.pointee.ticks.count {
            if p.pointee[idx].pointee.isEmpty() {
                continue
            }
            return Int64(idx - p.pointee.curr) * precision + lastTs
        }
        // no? but we've only checked the first level
        return Int64(p.pointee.ticks.count) * precision + lastTs
    }

    @inlinable @inline(__always)
    public mutating func nextTimeAccurate() -> Int64 {
        var precision = precisionMillis
        // for the first level:
        let p = self[0]
        for idx in p.pointee.curr ..< p.pointee.ticks.count {
            if p.pointee[idx].pointee.isEmpty() {
                continue
            }
            return Int64(idx - p.pointee.curr) * precision + lastTs
        }
        precision *= Int64(p.pointee.ticks.count)
        for levelIdx in 1 ..< levels.count {
            let p = self[levelIdx]
            for idx in p.pointee.curr ..< p.pointee.ticks.count {
                if p.pointee[idx].pointee.isEmpty() {
                    continue
                }
                var minTriggerTime = Int64.max
                for pnode in p.pointee[idx].pointee.nodeSeq() {
                    if pnode.pointee.triggerTime < minTriggerTime {
                        minTriggerTime = pnode.pointee.triggerTime
                    }
                }
                return minTriggerTime
            }
            precision *= Int64(p.pointee.ticks.count)
        }
        return Int64.max
    }

    @inlinable @inline(__always)
    public mutating func poll(currentTimeMillis: Int64) -> LinkedListRef<NODE> {
        if currentTimeMillis < lastTs {
            return LinkedListRef<NODE>()
        }
        let lastTs = lastTs
        var currentTimeMillis = currentTimeMillis
        if currentTimeMillis % precisionMillis != 0 {
            currentTimeMillis = currentTimeMillis - (currentTimeMillis % precisionMillis)
        }
        self.lastTs = currentTimeMillis

        let ret = LinkedListRef<NODE>()
        var tail: UnsafeMutablePointer<NODE> = Unsafe.addressOf(evenMoreUnsafe: &ret.pointee.head)

        var precision = precisionMillis
        for levelIdx in 0 ..< levels.count {
            let p = self[levelIdx]
            let toIndex = p.pointee.pollToIndex(last: lastTs, to: currentTimeMillis, precision: precision)
            let lastIndex = if levelIdx == 0 {
                // for the first level, elems on the last tick need to be directly put into the returning list
                min(p.pointee.ticks.count - 1, toIndex)
            } else {
                // for other levels, elems on the last tick should be expand into prev level and optionally put into the returning list
                min(p.pointee.ticks.count - 2, toIndex - 1)
            }
            if p.pointee.curr <= lastIndex { // may only expand without traversing ticks in current level
                for idx in p.pointee.curr ... lastIndex {
                    if p.pointee[idx].pointee.isEmpty() {
                        // empty
                        continue
                    }
                    let first: UnsafeMutablePointer<NODE> = Unsafe.raw2mutptr(p.pointee[idx].pointee.head.vars.___next_!)
                    let last: UnsafeMutablePointer<NODE> = Unsafe.raw2mutptr(p.pointee[idx].pointee.head.vars.___prev_!)
                    first.pointee.vars.___prev_ = Unsafe.ptr2raw(tail)
                    tail.pointee.vars.___next_ = Unsafe.ptr2raw(first)
                    tail = last
                    // clear the node
                    p.pointee[idx].pointee.selfInit()
                }
            }
            p.pointee.curr = toIndex % p.pointee.ticks.count
            expand(level: levelIdx, current: currentTimeMillis, firstLevelPrecision: precisionMillis, currentLevelPrecision: precision, list: ret, tail: &tail)
            if toIndex < p.pointee.ticks.count {
                break
            }
            precision *= Int64(p.pointee.ticks.count)
        }
        tail.pointee.vars.___next_ = Unsafe.addressOf(&ret.pointee.head)
        ret.pointee.head.vars.___prev_ = Unsafe.ptr2raw(tail)

        return ret
    }

    @inlinable @inline(__always)
    mutating func expand(level: Int, current: Int64, firstLevelPrecision: Int64, currentLevelPrecision: Int64, list: LinkedListRef<NODE>, tail: inout UnsafeMutablePointer<NODE>) {
        if level == 0 {
            return
        }
        let p = self[level]
        if p.pointee[p.pointee.curr].pointee.isEmpty() {
            return
        }

        let pprev = self[level - 1]
        let prevPrecision = currentLevelPrecision / Int64(pprev.pointee.ticks.count)
        for pn in p.pointee[p.pointee.curr].pointee.nodeSeq() {
            pn.pointee.removeSelf(releaseRef: false)
            let triggerTime = if pn.pointee.triggerTime % firstLevelPrecision == 0 {
                pn.pointee.triggerTime
            } else {
                pn.pointee.triggerTime - pn.pointee.triggerTime % firstLevelPrecision
            }
            if triggerTime <= current {
                // should trigger
                tail.pointee.vars.___next_ = Unsafe.ptr2raw(pn)
                pn.pointee.vars.___prev_ = Unsafe.ptr2raw(tail)
                pn.pointee.vars.___next_ = Unsafe.addressOf(&list.pointee.head)
                tail = pn
            } else {
                // should be put into ticks
                pprev.pointee.add(last: current, precision: prevPrecision, n: &pn.pointee)
                let raw = Unsafe.ptr2raw(pn)
                Unsafe.releaseNativeRef(raw.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
            }
        }
        expand(level: level - 1, current: current, firstLevelPrecision: firstLevelPrecision, currentLevelPrecision: prevPrecision, list: list, tail: &tail)
    }

    @inlinable @inline(__always)
    public mutating func destroy() {
        for i in 0 ..< levels.count {
            for j in 0 ..< levels[i].ticks.count {
                levels[i].ticks[j].destroy()
            }
        }
    }
}

public class TimeWheelRef<NODE: TimeNode> {
    public var pointee: TimeWheel<NODE>

    @inlinable @inline(__always)
    public init(currentTimeMillis: Int64, precisionMillis: Int64, levelTicks: Int, _ moreTicks: Int...) {
        pointee = .init(currentTimeMillis: currentTimeMillis, precisionMillis: precisionMillis, levelTicks: levelTicks, moreTicks)
    }

    @inlinable @inline(__always)
    public func poll(currentTimeMillis: Int64) -> LinkedListRef<NODE> {
        return pointee.poll(currentTimeMillis: currentTimeMillis)
    }

    deinit {
        pointee.destroy()
    }
}

public protocol TimeNode<V>: LinkedListNode {
    var triggerTime: Int64 { get set }
}

public extension TimeNode {
    @inlinable @inline(__always)
    mutating func addInto(wheel: inout TimeWheel<Self>) -> Bool {
        return wheel.add(n: &self)
    }

    @inlinable @inline(__always)
    mutating func addInto(wheel: TimeWheelRef<Self>) -> Bool {
        return wheel.pointee.add(n: &self)
    }
}

public struct TimeLevel<NODE: TimeNode> {
    @usableFromInline var curr: Int = 0
    public var ticks: [LinkedList<NODE>]

    @inlinable @inline(__always)
    mutating func selfInit(tickCount: Int) {
        ticks = .init(unsafeUninitializedCapacity: tickCount) { _, sz in sz = tickCount }
        let u8p: UnsafeMutablePointer<UInt8> = Unsafe.raw2mutptr(ticks.withUnsafeBufferPointer { p in p.baseAddress! })
        let memSize = MemoryLayout<LinkedList<NODE>>.stride
        for i in 0 ..< tickCount * memSize {
            u8p.advanced(by: i).pointee = 0
        }
        for i in 0 ..< tickCount {
            ticks[i].selfInit()
        }
    }

    @inlinable @inline(__always)
    public subscript(_ index: Int) -> UnsafeMutablePointer<LinkedList<NODE>> {
        @inlinable @inline(__always)
        mutating get {
            let ret = Unsafe.addressOf(evenMoreUnsafe: &ticks[index])
            return ret
        }
    }

    @inlinable @inline(__always)
    func maxTime(last: Int64, precision: Int64, isLastLevel: Bool) -> Int64 {
        if isLastLevel {
            return last + precision * Int64(ticks.count)
        } else {
            return last + precision * Int64(ticks.count - curr)
        }
    }

    @inlinable @inline(__always)
    mutating func add(last: Int64, precision: Int64, n: inout NODE) {
        var index = Int((n.triggerTime - last) / precision) + curr
        index = index % ticks.count
        n.addInto(list: &(self[index].pointee))
    }

    @inlinable @inline(__always)
    func pollToIndex(last: Int64, to: Int64, precision: Int64) -> Int {
        return Int((to - last) / precision) + curr
    }
}
