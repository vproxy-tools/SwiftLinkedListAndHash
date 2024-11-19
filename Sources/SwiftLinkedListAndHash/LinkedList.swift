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

    mutating func addInto(list: inout LinkedList<Self>) {
        let pself = Unsafe.addressOf(&self)
        let phead = Unsafe.addressOf(&list)
        _ = Unmanaged<V>.fromOpaque(pself.advanced(by: -(Self.fieldOffset + CLASS_HEADER_LEN))).retain()
        let plast = list.head.vars.___prev_!
        let last_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(plast.advanced(by: 8))
        let head_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(phead)
        let self_prev: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself)
        let self_next: UnsafeMutablePointer<UnsafeRawPointer> = Unsafe.raw2mutptr(pself.advanced(by: 8))

        // last->next = self
        last_next.pointee = pself
        // self->next = head
        self_next.pointee = phead
        // head->prev = self
        head_prev.pointee = pself
        // self->prev = last
        self_prev.pointee = plast
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
