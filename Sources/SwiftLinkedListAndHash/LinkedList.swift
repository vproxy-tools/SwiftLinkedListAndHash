public struct LinkedList<NODE: LinkedListNode> {
    public var head = NODE()

    @inlinable @inline(__always)
    public init() {}

    @inlinable @inline(__always)
    public mutating func selfInit() {
        head.vars.___prev_ = Unsafe.addressOf(&head)
        head.vars.___next_ = Unsafe.addressOf(&head)
    }

    @inlinable @inline(__always)
    public mutating func first() -> NODE.V? {
        if head.vars.___next_ == nil || head.vars.___next_ == Unsafe.addressOf(&head) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(head.vars.___next_!.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
    }

    @inlinable @inline(__always)
    public mutating func last() -> NODE.V? {
        if head.vars.___prev_ == nil || head.vars.___prev_ == Unsafe.addressOf(&head) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(head.vars.___prev_!.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
    }

    @inlinable @inline(__always)
    public mutating func seq() -> LinkedListSeq<NODE.V> {
        return LinkedListSeq(head: Unsafe.addressOf(&head), offset: NODE.fieldOffset + CLASS_HEADER_LEN)
    }

    @inlinable @inline(__always)
    public mutating func nodeSeq() -> LinkedListNodeSeq<NODE> {
        return LinkedListNodeSeq(head: Unsafe.addressOf(&head), offset: NODE.fieldOffset + CLASS_HEADER_LEN)
    }

    @inlinable @inline(__always)
    public mutating func destroy() {
        if head.vars.___next_ == nil {
            return
        }
        let head = Unsafe.addressOf(&head)
        var n = self.head.vars.___next_!
        while n != head {
            let prev: UnsafeMutablePointer<UnsafeRawPointer?> = Unsafe.raw2mutptr(n)
            let next: UnsafeMutablePointer<UnsafeRawPointer?> = Unsafe.raw2mutptr(n.advanced(by: 8))
            let nx = next.pointee!
            prev.pointee = n
            next.pointee = n
            Unsafe.releaseNativeRef(n.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
            n = nx
        }
        self.head.vars.___prev_ = nil
        self.head.vars.___next_ = nil
    }

    @inlinable @inline(__always)
    public var count: Int {
        @inlinable @inline(__always)
        mutating get {
            var ret = 0
            var node = head.vars.___next_
            let head = Unsafe.addressOf(&head)
            while node != head {
                ret += 1
                let p: UnsafePointer<NODE> = Unsafe.raw2ptr(node!)
                node = p.pointee.vars.___next_
            }
            return ret
        }
    }

    @inlinable @inline(__always)
    public mutating func isEmpty() -> Bool {
        let head = Unsafe.addressOf(&head)
        return self.head.vars.___next_ == head || self.head.vars.___next_ == nil
    }
}

public class LinkedListRef<NODE: LinkedListNode> {
    public var pointee = LinkedList<NODE>()
    @inlinable @inline(__always)
    public var count: Int { pointee.count }

    @inlinable @inline(__always)
    public init() {
        pointee.selfInit()
    }

    @inlinable @inline(__always)
    public func seq() -> LinkedListSeq<NODE.V> { pointee.seq() }

    @inlinable @inline(__always)
    public func nodeSeq() -> LinkedListNodeSeq<NODE> { pointee.nodeSeq() }

    @inlinable @inline(__always)
    public func isEmpty() -> Bool { pointee.isEmpty() }

    @inlinable @inline(__always)
    deinit {
        pointee.destroy()
    }
}

public struct LinkedListNodeVars {
    public var ___prev_: UnsafeRawPointer?
    public var ___next_: UnsafeRawPointer?

    @inlinable @inline(__always)
    public init() {}
}

public protocol LinkedListNode<V> {
    associatedtype V: AnyObject

    var vars: LinkedListNodeVars { get set }
    init()

    static var fieldOffset: Int { get }
}

public extension LinkedListNode {
    @inlinable @inline(__always)
    mutating func element() -> V {
        let p = Unsafe.addressOf(&self).advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))
        return Unsafe.convertFromNativeKeepRef(p)
    }

    @inlinable @inline(__always)
    mutating func prev(list: inout LinkedList<Self>) -> V? {
        let phead = Unsafe.addressOf(&list.head)
        if vars.___prev_ == nil || vars.___prev_ == phead || vars.___prev_ == Unsafe.addressOf(&self) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(vars.___prev_!.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
    }

    @inlinable @inline(__always)
    mutating func next(list: inout LinkedList<Self>) -> V? {
        let phead = Unsafe.addressOf(&list.head)
        if vars.___next_ == nil || vars.___next_ == phead || vars.___next_ == Unsafe.addressOf(&self) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(vars.___next_!.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
    }

    @inlinable @inline(__always)
    mutating func add(before pnode: UnsafeRawPointer) {
        let pself = Unsafe.addressOf(&self)
        Unsafe.retainNativeRef(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
        let node_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pnode)
        let pprev = node_prev.pointee
        let prev_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pprev.advanced(by: 8))
        let self_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself)
        let self_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself.advanced(by: 8))

        // prev->next = self
        prev_next.pointee = pself
        // self->next = node
        self_next.pointee = pnode
        // node->prev = self
        node_prev.pointee = pself
        // self->prev = prev
        self_prev.pointee = pprev
    }

    @inlinable @inline(__always)
    mutating func add(after pnode: UnsafeRawPointer) {
        let pself = Unsafe.addressOf(&self)
        Unsafe.retainNativeRef(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
        let node_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pnode.advanced(by: 8))
        let pnext = node_next.pointee
        let next_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pnext)
        let self_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself)
        let self_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself.advanced(by: 8))

        // node->next = self
        node_next.pointee = pself
        // self->next = next
        self_next.pointee = pnext
        // next->prev = self
        next_prev.pointee = pself
        // self->prev = node
        self_prev.pointee = pnode
    }

    @inlinable @inline(__always)
    mutating func add(before element: V) {
        let pnode = Unsafe.convertToNativeKeepRef(element).advanced(by: Self.fieldOffset + CLASS_HEADER_LEN)
        add(before: pnode)
    }

    @inlinable @inline(__always)
    mutating func add(after element: V) {
        let pnode = Unsafe.convertToNativeKeepRef(element).advanced(by: Self.fieldOffset + CLASS_HEADER_LEN)
        add(after: pnode)
    }

    @inlinable @inline(__always)
    mutating func add(before node: inout Self) {
        add(before: Unsafe.addressOf(&node))
    }

    @inlinable @inline(__always)
    mutating func add(after node: inout Self) {
        add(after: Unsafe.addressOf(&node))
    }

    @inlinable @inline(__always)
    mutating func addInto(list: inout LinkedList<Self>) {
        add(before: &list.head)
    }

    @inlinable @inline(__always)
    mutating func insertInto(list: inout LinkedList<Self>) {
        add(after: &list.head)
    }

    @inlinable @inline(__always)
    mutating func addInto(list: LinkedListRef<Self>) {
        add(before: &list.pointee.head)
    }

    @inlinable @inline(__always)
    mutating func insertInto(list: LinkedListRef<Self>) {
        add(after: &list.pointee.head)
    }

    @inlinable @inline(__always)
    var isInList: Bool {
        @inlinable @inline(__always)
        mutating get {
            let pself = Unsafe.addressOf(&self)
            let pprev = vars.___prev_
            let pnext = vars.___next_
            return pprev != pself && pnext != pself && pprev != nil && pnext != nil
        }
    }

    @inlinable @inline(__always)
    mutating func removeSelf() {
        removeSelf(releaseRef: true)
    }
}

extension LinkedListNode {
    @inlinable @inline(__always)
    mutating func removeSelf(releaseRef: Bool) {
        if !isInList {
            return
        }

        let pself = Unsafe.addressOf(&self)
        let pprev = vars.___prev_!
        let pnext = vars.___next_!
        let prev_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pprev.advanced(by: 8))
        let next_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pnext)
        let self_prev: UnsafeMutablePointer<UnsafeRawPointer?> = Unsafe.raw2mutptr(pself)
        let self_next: UnsafeMutablePointer<UnsafeRawPointer?> = Unsafe.raw2mutptr(pself.advanced(by: 8))

        // self->prev->next = self->next
        prev_next.pointee = pnext
        // self->next->prev = self->prev
        next_prev.pointee = pprev
        // self->prev = nil
        self_prev.pointee = pself
        // self->next = nil
        self_next.pointee = pself

        if releaseRef {
            Unsafe.releaseNativeRef(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
        }
    }
}

public struct LinkedListSeq<V: AnyObject>: Sequence {
    public typealias Element = V
    public typealias Iterator = LinkedListIterator<V>
    @usableFromInline var head: UnsafeRawPointer
    @usableFromInline let offset: Int

    @inlinable @inline(__always)
    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        self.offset = offset
    }

    @inlinable @inline(__always)
    public func makeIterator() -> LinkedListIterator<V> {
        return LinkedListIterator(head: head, offset: offset)
    }
}

public struct LinkedListIterator<V: AnyObject>: IteratorProtocol {
    public typealias Element = V
    @usableFromInline let head: UnsafeRawPointer
    @usableFromInline var current: UnsafeRawPointer?
    @usableFromInline let offset: Int

    @inlinable @inline(__always)
    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        let next: UnsafePointer<UnsafeRawPointer?> = Unsafe.raw2ptr(head.advanced(by: 8))
        current = next.pointee
        self.offset = offset
    }

    @inlinable @inline(__always)
    public mutating func next() -> V? {
        if current == nil || current == head {
            return nil
        }
        let e: V = Unsafe.convertFromNativeKeepRef(current!.advanced(by: -offset))
        let next: UnsafePointer<UnsafeRawPointer?> = Unsafe.raw2ptr(current!.advanced(by: 8))
        current = next.pointee
        return e
    }
}

public struct LinkedListNodeSeq<NODE: LinkedListNode>: Sequence {
    public typealias Element = UnsafeMutablePointer<NODE>
    public typealias Iterator = LinkedListNodeIterator<NODE>
    @usableFromInline var head: UnsafeRawPointer
    @usableFromInline let offset: Int

    @inlinable @inline(__always)
    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        self.offset = offset
    }

    @inlinable @inline(__always)
    public func makeIterator() -> LinkedListNodeIterator<NODE> {
        return LinkedListNodeIterator(head: head, offset: offset)
    }
}

public struct LinkedListNodeIterator<NODE: LinkedListNode>: IteratorProtocol {
    public typealias Element = UnsafeMutablePointer<NODE>
    @usableFromInline let head: UnsafeRawPointer
    @usableFromInline var current: UnsafeRawPointer?
    @usableFromInline let offset: Int

    @inlinable @inline(__always)
    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        let next: UnsafePointer<UnsafeRawPointer?> = Unsafe.raw2ptr(head.advanced(by: 8))
        current = next.pointee
        self.offset = offset
    }

    @inlinable @inline(__always)
    public mutating func next() -> UnsafeMutablePointer<NODE>? {
        if current == nil || current == head {
            return nil
        }
        let e: UnsafeMutablePointer<NODE> = Unsafe.raw2mutptr(current!)
        let next: UnsafePointer<UnsafeRawPointer?> = Unsafe.raw2ptr(current!.advanced(by: 8))
        current = next.pointee
        return e
    }
}
