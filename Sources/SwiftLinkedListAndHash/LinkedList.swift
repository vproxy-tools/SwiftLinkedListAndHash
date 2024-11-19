public struct LinkedList<NODE: LinkedListNode> {
    public var head = NODE()

    public init() {}

    public mutating func selfInit() {
        head.vars.___prev_ = Unsafe.addressOf(&head)
        head.vars.___next_ = Unsafe.addressOf(&head)
    }

    public mutating func first() -> NODE.V? {
        if head.vars.___next_ == nil || head.vars.___next_ == Unsafe.addressOf(&head) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(head.vars.___next_!.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
    }

    public mutating func last() -> NODE.V? {
        if head.vars.___prev_ == nil || head.vars.___prev_ == Unsafe.addressOf(&head) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(head.vars.___prev_!.advanced(by: -(NODE.fieldOffset + CLASS_HEADER_LEN)))
    }

    public mutating func seq() -> LinkedListNodeSeq<NODE.V> {
        return LinkedListNodeSeq(head: Unsafe.addressOf(&head), offset: NODE.fieldOffset + CLASS_HEADER_LEN)
    }

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
}

let CLASS_HEADER_LEN = 16

public struct LinkedListNodeVars {
    public var ___prev_: UnsafeRawPointer?
    public var ___next_: UnsafeRawPointer?
    public init() {}
}

public protocol LinkedListNode<V>: ~Copyable {
    associatedtype V: AnyObject

    var vars: LinkedListNodeVars { get set }
    init()

    static var fieldOffset: Int { get }
}

public extension LinkedListNode {
    mutating func element() -> V {
        let p = Unsafe.addressOf(&self).advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))
        return Unsafe.convertFromNativeKeepRef(p)
    }

    mutating func prev(list: inout LinkedList<Self>) -> V? {
        let phead = Unsafe.addressOf(&list.head)
        if vars.___prev_ == nil || vars.___prev_ == phead || vars.___prev_ == Unsafe.addressOf(&self) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(vars.___prev_!.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
    }

    mutating func next(list: inout LinkedList<Self>) -> V? {
        let phead = Unsafe.addressOf(&list.head)
        if vars.___next_ == nil || vars.___next_ == phead || vars.___next_ == Unsafe.addressOf(&self) {
            return nil
        }
        return Unsafe.convertFromNativeKeepRef(vars.___next_!.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN)))
    }

    mutating func add(before pnode: UnsafeRawPointer) {
        let pself = Unsafe.addressOf(&self)
        _ = Unmanaged<V>.fromOpaque(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))).retain()
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

    mutating func add(after pnode: UnsafeRawPointer) {
        let pself = Unsafe.addressOf(&self)
        _ = Unmanaged<V>.fromOpaque(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))).retain()
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

    mutating func add(before element: V) {
        let pnode = Unsafe.convertToNativeKeepRef(element).advanced(by: Self.fieldOffset + CLASS_HEADER_LEN)
        add(before: pnode)
    }

    mutating func add(after element: V) {
        let pnode = Unsafe.convertToNativeKeepRef(element).advanced(by: Self.fieldOffset + CLASS_HEADER_LEN)
        add(after: pnode)
    }

    mutating func add(before node: inout Self) {
        add(before: Unsafe.addressOf(&node))
    }

    mutating func add(after node: inout Self) {
        add(after: Unsafe.addressOf(&node))
    }

    mutating func addInto(list: inout LinkedList<Self>) {
        add(before: &list.head)
    }

    mutating func insertInto(list: inout LinkedList<Self>) {
        add(after: &list.head)
    }

    mutating func removeSelf() {
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

        Unmanaged<V>.fromOpaque(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))).release()
    }
}

public struct LinkedListNodeSeq<V: AnyObject>: Sequence {
    public typealias Element = V
    public typealias Iterator = LinkedListNodeIterator<V>
    private var head: UnsafeRawPointer
    private let offset: Int

    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        self.offset = offset
    }

    public func makeIterator() -> LinkedListNodeIterator<V> {
        return LinkedListNodeIterator(head: head, offset: offset)
    }
}

public struct LinkedListNodeIterator<V: AnyObject>: IteratorProtocol {
    public typealias Element = V
    private let head: UnsafeRawPointer
    private var current: UnsafeRawPointer?
    private let offset: Int

    init(head: UnsafeRawPointer, offset: Int) {
        self.head = head
        let next: UnsafePointer<UnsafeRawPointer?> = Unsafe.raw2ptr(head.advanced(by: 8))
        current = next.pointee
        self.offset = offset
    }

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
