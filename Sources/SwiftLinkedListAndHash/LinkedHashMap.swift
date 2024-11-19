public typealias LinkedHashMap<ENTRY> = GeneralLinkedHashMap<LinkedHash<ENTRY>, ENTRY> where ENTRY: LinkedHashMapEntry

public struct GeneralLinkedHashMap<HASH, ENTRY: LinkedHashMapEntry>: ~Copyable where HASH: LinkedHashProtocol<ENTRY> {
    private var modsz: Int { hashes.count - 1 }
    public var hashes: [HASH]

    public init(_ hashSizeHint: Int) {
        hashes = [HASH](repeating: HASH(), count: Self.findNextPowerOf2(hashSizeHint))
        for idx in hashes.indices {
            hashes[idx].selfInit()
        }
    }

    @inline(__always)
    private static func findNextPowerOf2(_ n: Int) -> Int {
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

    public func indexOf(key: ENTRY.K) -> Int {
        return key.hashValue & modsz
    }

    public subscript(_ key: ENTRY.K) -> ENTRY.V? {
        mutating get {
            let idx = key.hashValue & modsz
            return hashes[idx][key]
        }
    }

    public mutating func destroy() {
        for i in hashes.indices {
            hashes[i].destroy()
        }
    }
}

public protocol LinkedHashProtocol<ENTRY>: ~Copyable {
    associatedtype ENTRY: LinkedHashMapEntry

    var list: LinkedList<ENTRY> { get set }
    init()
}

public extension LinkedHashProtocol {
    mutating func selfInit() {
        list.selfInit()
    }

    subscript(key: ENTRY.K) -> ENTRY.V? {
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

    mutating func destroy() {
        list.destroy()
    }
}

public struct LinkedHash<ENTRY: LinkedHashMapEntry>: LinkedHashProtocol {
    public var list = LinkedList<ENTRY>()
    public init() {}
}

public protocol LinkedHashMapEntry<K, V>: LinkedListNode {
    associatedtype K: Hashable

    mutating func key() -> K
}

public extension LinkedHashMapEntry {
    mutating func addInto<HASH>(map: inout GeneralLinkedHashMap<HASH, Self>) where HASH: LinkedHashProtocol<Self> {
        addInto(list: &(map.hashes[map.indexOf(key: key())].list))
    }

    mutating func insertInto<HASH>(map: inout GeneralLinkedHashMap<HASH, Self>) where HASH: LinkedHashProtocol<Self> {
        insertInto(list: &(map.hashes[map.indexOf(key: key())].list))
    }
}
