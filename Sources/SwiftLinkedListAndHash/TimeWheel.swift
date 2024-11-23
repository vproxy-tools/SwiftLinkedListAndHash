public struct TimeWheel<NODE: TimeNode> {
    @usableFromInline let precisionMillis: Int64
    @usableFromInline let totalLevels: Int
    @usableFromInline let maxTime: Int64
    @usableFromInline let levels: [UInt64]

    @usableFromInline var lastTs: Int64 = 0

    // for example, .init(precisionMillis: 1000, levelTicks: 60, 60, 24)
    // would create a timewheel for one day
    // to be more precise, safely 23 hours, max 24 hours
    @inlinable @inline(__always)
    public init(currentTimeMillis: Int64, precisionMillis: Int64, levelTicks: Int, _ moreTicks: Int...) {
        lastTs = currentTimeMillis
        self.precisionMillis = precisionMillis
        totalLevels = 1 + moreTicks.count
        var maxTime = precisionMillis * Int64(levelTicks)
        for t in moreTicks {
            maxTime *= Int64(t)
        }
        self.maxTime = maxTime
        let memSize = MemoryLayout<TimeLevel<NODE>>.stride
        levels = [UInt64](repeating: 0, count: (1 + moreTicks.count) * memSize / 8)

        self[0].pointee.selfInit(tickCount: levelTicks)
        for i in 0 ..< moreTicks.count {
            self[i + 1].pointee.selfInit(tickCount: moreTicks[i])
        }
    }

    @inlinable @inline(__always)
    subscript(_ index: Int) -> UnsafeMutablePointer<TimeLevel<NODE>> {
        let p: UnsafeMutablePointer<TimeLevel<NODE>> = Unsafe.raw2mutptr(levels.withUnsafeBufferPointer { p in p.baseAddress! })
        return p.advanced(by: index)
    }

    @inlinable @inline(__always)
    func add(n: inout NODE) -> Bool {
        if n.triggerTime <= lastTs {
            let p = self[0]
            n.addInto(list: &(p.pointee[p.pointee.curr].pointee))
            return true
        }

        var precision = precisionMillis
        for i in 0 ..< totalLevels {
            let p = self[i]
            if p.pointee.maxTime(current: lastTs, precision: precision) < n.triggerTime {
                precision *= Int64(p.pointee.tickCount)
                continue
            }
            p.pointee.add(current: lastTs, precision: precision, n: &n)
            return true
        }
        return false
    }

    @inlinable @inline(__always)
    public func nextTimeFast() -> Int64 {
        let precision = precisionMillis
        // for the first level:
        let p = self[0]
        for idx in p.pointee.curr ..< p.pointee.tickCount {
            if p.pointee[idx].pointee.head.vars.___next_ == Unsafe.addressOf(&p.pointee[idx].pointee.head) {
                // empty
                continue
            }
            return Int64(idx - p.pointee.curr) * precision + lastTs
        }
        // no? but we've only checked the first level
        return Int64(p.pointee.tickCount) * precision + lastTs
    }

    @inlinable @inline(__always)
    public func nextTimeAccurate() -> Int64 {
        var precision = precisionMillis
        // for the first level:
        let p = self[0]
        for idx in p.pointee.curr ..< p.pointee.tickCount {
            if p.pointee[idx].pointee.head.vars.___next_ == Unsafe.addressOf(&p.pointee[idx].pointee.head) {
                // empty
                continue
            }
            return Int64(idx - p.pointee.curr) * precision + lastTs
        }
        precision *= Int64(p.pointee.tickCount)
        for levelIdx in 1 ..< totalLevels {
            let p = self[levelIdx]
            for idx in p.pointee.curr ..< p.pointee.tickCount {
                if p.pointee[idx].pointee.head.vars.___next_ == Unsafe.addressOf(&p.pointee[idx].pointee.head) {
                    // empty
                    continue
                }
                var minTriggerTime = Int64.max
                let head = Unsafe.addressOf(&p.pointee[idx].pointee.head)
                var node = p.pointee[idx].pointee.head.vars.___next_
                while node != head {
                    let pnode: UnsafePointer<NODE> = Unsafe.raw2ptr(node!)
                    if pnode.pointee.triggerTime < minTriggerTime {
                        minTriggerTime = pnode.pointee.triggerTime
                    }
                    node = pnode.pointee.vars.___next_
                }
                return minTriggerTime
            }
            precision *= Int64(p.pointee.tickCount)
        }
        return Int64.max
    }

    @inlinable @inline(__always)
    public mutating func poll(currentTimeMillis: Int64) -> LinkedListRef<NODE> {
        let lastTs = lastTs
        self.lastTs = currentTimeMillis

        let ret = LinkedListRef<NODE>()
        ret.list.selfInit()
        var tail: UnsafeMutablePointer<NODE> = Unsafe.raw2mutptr(Unsafe.addressOf(&ret.list.head))

        var precision = precisionMillis
        for levelIdx in 0 ..< totalLevels {
            let p = self[levelIdx]
            let toIndex = p.pointee.pollToIndex(current: lastTs, to: currentTimeMillis, precision: precision)
            let lastIndex = if levelIdx == 0 {
                // for the first level, elems on the last tick need to be directly put into the returning list
                min(p.pointee.tickCount - 1, toIndex)
            } else {
                // for other levels, elems on the last tick should be expand into prev level and optionally put into the returning list
                toIndex - 1
            }
            if p.pointee.curr <= lastIndex { // may only expand without traversing ticks in current level
                for idx in p.pointee.curr ... lastIndex {
                    if p.pointee[idx].pointee.head.vars.___next_ == Unsafe.addressOf(&p.pointee[idx].pointee.head) {
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
            if toIndex < p.pointee.tickCount {
                p.pointee.curr = toIndex
            } else {
                p.pointee.curr = 0
            }
            expand(level: levelIdx, current: currentTimeMillis, precision: precision, list: ret, tail: &tail)
            if toIndex < p.pointee.tickCount {
                break
            }
            precision *= Int64(p.pointee.tickCount)
        }
        tail.pointee.vars.___next_ = Unsafe.addressOf(&ret.list.head)
        ret.list.head.vars.___prev_ = Unsafe.ptr2raw(tail)

        return ret
    }

    @inlinable @inline(__always)
    func expand(level: Int, current: Int64, precision: Int64, list: LinkedListRef<NODE>, tail: inout UnsafeMutablePointer<NODE>) {
        if level == 0 {
            return
        }
        let p = self[level]
        let prevp = self[level - 1]
        let prevPrecision = precision / Int64(p.pointee.tickCount)
        for e in p.pointee[p.pointee.curr].pointee.seq() {
            let pn: UnsafeMutablePointer<NODE> =
                Unsafe.raw2mutptr(Unsafe.convertToNativeKeepRef(e).advanced(by: NODE.fieldOffset + CLASS_HEADER_LEN))
            pn.pointee.removeSelf(releaseRef: false)
            let triggerTime = if pn.pointee.triggerTime % prevPrecision == 0 {
                pn.pointee.triggerTime
            } else {
                pn.pointee.triggerTime - pn.pointee.triggerTime % prevPrecision
            }
            if triggerTime <= current {
                // should trigger
                tail.pointee.vars.___next_ = Unsafe.ptr2raw(pn)
                pn.pointee.vars.___prev_ = Unsafe.ptr2raw(tail)
                pn.pointee.vars.___next_ = Unsafe.addressOf(&list.list.head)
                tail = pn
            } else {
                // should be put into ticks
                prevp.pointee.add(current: current, precision: prevPrecision, n: &pn.pointee)
                let raw = Unsafe.ptr2raw(pn)
                Unsafe.releaseNativeRef(raw.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
            }
        }
    }

    @inlinable @inline(__always)
    public func destroy() {
        for i in 0 ..< totalLevels {
            let p = self[i]
            for j in 0 ..< p.pointee.tickCount {
                p.pointee[j].pointee.destroy()
            }
        }
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
}

@usableFromInline
struct TimeLevel<NODE: TimeNode> {
    @usableFromInline var tickCount: Int
    @usableFromInline var curr: Int = 0
    @usableFromInline var ticks: [UInt64]

    @inlinable @inline(__always)
    mutating func selfInit(tickCount: Int) {
        self.tickCount = tickCount
        let memSize = MemoryLayout<LinkedList<NODE>>.stride
        ticks = [UInt64](repeating: 0, count: tickCount * memSize / 8)
        for i in 0 ..< tickCount {
            self[i].pointee.selfInit()
        }
    }

    @inlinable @inline(__always)
    subscript(_ index: Int) -> UnsafeMutablePointer<LinkedList<NODE>> {
        let p: UnsafeMutablePointer<LinkedList<NODE>> = Unsafe.raw2mutptr(ticks.withUnsafeBufferPointer { p in p.baseAddress! })
        return p.advanced(by: index)
    }

    @inlinable @inline(__always)
    func maxTime(current: Int64, precision: Int64) -> Int64 {
        var current = current
        if current % precision != 0 {
            current -= current % precision
        }
        return current + precision * Int64(tickCount - curr)
    }

    @inlinable @inline(__always)
    func add(current: Int64, precision: Int64, n: inout NODE) {
        var current = current
        if current % precision != 0 {
            current -= current % precision
        }
        n.addInto(list: &(self[Int((n.triggerTime - current) / precision) + curr].pointee))
    }

    @inlinable @inline(__always)
    func pollToIndex(current: Int64, to: Int64, precision: Int64) -> Int {
        var current = current
        if current % precision != 0 {
            current -= current % precision
        }
        let idx = Int((to - current) / precision) + curr
        if idx >= tickCount {
            return tickCount
        }
        return idx
    }
}
