import Testing
import SwiftLinkedListAndHash

class TestClassLayout {
    @Test func classHeader() {
        let cls = MyClass(a: 1)
        let p = withUnsafePointer(to: &cls.a) { p in UnsafeMutableRawPointer(mutating: p) }
        let c = Unmanaged<MyClass>.passUnretained(cls).toOpaque()
        #expect(Int(p - c) == 16)
    }
}

class MyClass {
    var a: Int
    init(a: Int) {
        self.a = a
    }
}
