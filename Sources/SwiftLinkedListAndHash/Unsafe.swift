@usableFromInline class Unsafe {
    private init() {}

    @inlinable @inline(__always)
    public static func addressOf<E: ~Copyable>(_ v: inout E) -> UnsafeRawPointer {
        return withUnsafePointer(to: &v) { p in ptr2raw(p) }
    }

    @inlinable @inline(__always)
    public static func raw2ptr<T>(_ raw: UnsafeRawPointer) -> UnsafePointer<T> {
        return raw.assumingMemoryBound(to: T.self)
    }

    @inlinable @inline(__always)
    public static func raw2mutptr<T>(_ raw: UnsafeRawPointer) -> UnsafeMutablePointer<T> {
        let p = raw.assumingMemoryBound(to: T.self)
        return UnsafeMutablePointer(mutating: p)
    }

    @inlinable @inline(__always)
    public static func ptr2raw<T: ~Copyable>(_ p: UnsafePointer<T>) -> UnsafeRawPointer {
        return UnsafeRawPointer(p)
    }

    @inlinable @inline(__always)
    public static func convertToNativeKeepRef<T: AnyObject>(_ value: T) -> UnsafeMutableRawPointer {
        return Unmanaged<T>.passUnretained(value).toOpaque()
    }

    @inlinable @inline(__always)
    public static func convertFromNativeKeepRef<T: AnyObject>(_ p: UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(p).takeUnretainedValue()
    }

    @inlinable @inline(__always)
    public static func releaseNativeRef(_ p: UnsafeRawPointer) {
        Unmanaged<AnyObject>.fromOpaque(p).release()
    }

    @inlinable @inline(__always)
    public static func retainNativeRef(_ p: UnsafeRawPointer) {
        _ = Unmanaged<AnyObject>.fromOpaque(p).retain()
    }
}
