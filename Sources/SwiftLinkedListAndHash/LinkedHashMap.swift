public typealias LinkedHashMap<ENTRY> = GeneralLinkedHashMap<LinkedHash<ENTRY>, ENTRY> where ENTRY: LinkedHashMapEntry

public struct GeneralLinkedHashMap<HASH, ENTRY: LinkedHashMapEntry>: ~Copyable where HASH: LinkedHashProtocol<ENTRY> {
    @usableFromInline let modsz: Int
    @usableFromInline let hashes: [UInt64]

    @inlinable @inline(__always)
    public init(_ hashSizeHint: Int) {
        let size = Self.findNextPowerOf2(hashSizeHint)
        modsz = size - 1
        hashes = [UInt64](repeating: 0, count: size * MemoryLayout<HASH>.stride / 8)
        for idx in 0 ... modsz {
            self[idx].pointee.initStruct()
            self[idx].pointee.selfInit()
        }
    }

    @inlinable @inline(__always)
    static func findNextPowerOf2(_ n: Int) -> Int {
        if n <= 0 {
            return 1
        }
        if (n & (n - 1)) != 0 {
            return n
        }
        var n = n
        var count = 0
        while n != 0 {
            n >>= 1
            count += 1
        }
        return 1 << count
    }

    @inlinable @inline(__always)
    public subscript(_ i: Int) -> UnsafeMutablePointer<HASH> {
        let p: UnsafeMutablePointer<HASH> = Unsafe.raw2mutptr(hashes.withUnsafeBufferPointer { p in p.baseAddress! })
        return p.advanced(by: i)
    }

    @inlinable @inline(__always)
    public func indexOf(key: ENTRY.K) -> Int {
        return key.hashValue & modsz
    }

    @inlinable @inline(__always)
    public subscript(_ key: ENTRY.K) -> ENTRY.V? {
        @inlinable @inline(__always)
        mutating get { self[indexOf(key: key)].pointee[key] }
    }

    @inlinable @inline(__always)
    public mutating func destroy() {
        for i in 0 ... modsz {
            self[i].pointee.destroy()
        }
    }
}

public protocol LinkedHashProtocol<ENTRY>: ~Copyable {
    associatedtype ENTRY: LinkedHashMapEntry

    var list: LinkedList<ENTRY> { get set }
    mutating func initStruct()
}

public extension LinkedHashProtocol {
    @inlinable @inline(__always)
    mutating func selfInit() {
        list.selfInit()
    }

    @inlinable @inline(__always)
    subscript(key: ENTRY.K) -> ENTRY.V? {
        @inlinable @inline(__always)
        mutating get {
            for v in list.seq() {
                let p = Unsafe.convertToNativeKeepRef(v).advanced(by: ENTRY.fieldOffset + CLASS_HEADER_LEN)
                let e: UnsafeMutablePointer<ENTRY> = Unsafe.raw2mutptr(p)
                if e.pointee.key() == key {
                    return v
                }
            }
            return nil
        }
    }

    @inlinable @inline(__always)
    mutating func destroy() {
        list.destroy()
    }
}

public struct LinkedHash<ENTRY: LinkedHashMapEntry>: LinkedHashProtocol {
    public var list = LinkedList<ENTRY>()
    @inlinable @inline(__always)
    public init() {}
    public mutating func initStruct() {}
}

public protocol LinkedHashMapEntry<K, V>: LinkedListNode {
    associatedtype K: Hashable

    mutating func key() -> K
}

public extension LinkedHashMapEntry {
    @inlinable @inline(__always)
    mutating func addInto<HASH>(map: inout GeneralLinkedHashMap<HASH, Self>) where HASH: LinkedHashProtocol<Self> {
        addInto(list: &(map[map.indexOf(key: key())].pointee.list))
    }

    @inlinable @inline(__always)
    mutating func insertInto<HASH>(map: inout GeneralLinkedHashMap<HASH, Self>) where HASH: LinkedHashProtocol<Self> {
        insertInto(list: &(map[map.indexOf(key: key())].pointee.list))
    }
}
