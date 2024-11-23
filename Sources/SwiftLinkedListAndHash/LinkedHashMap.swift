public typealias LinkedHashMap<ENTRY: LinkedHashMapEntry> = GeneralLinkedHashMap<LinkedHash<ENTRY>, ENTRY>

public struct GeneralLinkedHashMap<HASH: LinkedHashProtocol<ENTRY>, ENTRY: LinkedHashMapEntry>: ~Copyable {
    @usableFromInline var modsz: Int { hashes.count - 1 }
    @usableFromInline var hashes: [HASH]

    @inlinable @inline(__always)
    public init(_ hashSizeHint: Int) {
        let size = Self.findNextPowerOf2(hashSizeHint)
        hashes = .init(unsafeUninitializedCapacity: size) { _, sz in sz = size }
        let u8p: UnsafeMutablePointer<UInt8> = Unsafe.raw2mutptr(hashes.withUnsafeBufferPointer { p in p.baseAddress! })
        for i in 0 ..< size * MemoryLayout<HASH>.stride {
            u8p.advanced(by: i).pointee = 0
        }
        for i in 0 ..< hashes.count {
            hashes[i].initStruct()
            hashes[i].selfInit()
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
        for i in 0 ..< hashes.count {
            hashes[i].destroy()
        }
    }
}

public typealias LinkedHashMapRef<ENTRY: LinkedHashMapEntry> = GeneralLinkedHashMapRef<LinkedHash<ENTRY>, ENTRY>

public class GeneralLinkedHashMapRef<HASH: LinkedHashProtocol<ENTRY>, ENTRY: LinkedHashMapEntry> {
    public var pointee: GeneralLinkedHashMap<HASH, ENTRY>

    @inlinable @inline(__always)
    public init(_ hashSizeHint: Int) {
        pointee = .init(hashSizeHint)
    }

    @inlinable @inline(__always)
    public subscript(_ key: ENTRY.K) -> ENTRY.V? { pointee[key] }

    @inlinable @inline(__always)
    deinit {
        pointee.destroy()
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
    mutating func addInto<HASH: LinkedHashProtocol<Self>>(map: inout GeneralLinkedHashMap<HASH, Self>) {
        addInto(list: &(map[map.indexOf(key: key())].pointee.list))
    }

    @inlinable @inline(__always)
    mutating func insertInto<HASH: LinkedHashProtocol<Self>>(map: inout GeneralLinkedHashMap<HASH, Self>) {
        insertInto(list: &(map[map.indexOf(key: key())].pointee.list))
    }

    @inlinable @inline(__always)
    mutating func addInto<HASH: LinkedHashProtocol<Self>>(map: GeneralLinkedHashMapRef<HASH, Self>) {
        addInto(map: &map.pointee)
    }

    @inlinable @inline(__always)
    mutating func insertInto<HASH: LinkedHashProtocol<Self>>(map: GeneralLinkedHashMapRef<HASH, Self>) {
        insertInto(map: &map.pointee)
    }
}
