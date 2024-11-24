# SwiftLinkedListAndHash

A Linux style linkedList implementation, and linkedHashMap based on the linkedList.

## Dependency

```swift
let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/vproxy-tools/SwiftLinkedListAndHash", branch: "stable"),
    ]
    // ...
)
```

```swift
import SwiftLinkedListAndHash
```

## LinkedList

### 1. define data type for `LinkedList`

```swift
class Elem {
    var node = ElemNode()
    let id: Int
    let name: String
    // init(...) { ... }
}

struct ElemNode: LinkedListNode {
    typealias V = Elem
    var vars = LinkedListNodeVars()
    static let fieldOffset = 0
}
```

There are a few things to note:

1. the `Elem` must be defined using `class` (as already guaranteed by the protocol `LinkedListNode`)
2. the `ElemNode` must be defined using `struct` (should be guaranteed by yourself)
3. the `fieldOffset` must be the offset from the first field of `Elem` to the location of the `vars` defined in the ElemNode (should be guaranteed by yourself)

It might be tricky to calculate the `fieldOffset` if you are not familiar with swift's memory layout.  
There's a simple way to do this, you could always put the `LinkedListNode` at the beginning of your data type, and if you want your object to be added into multiple `LinkedList`s, inc the fieldOffset by `16` for each `LinkedListNode` appeared in the data type.

e.g. If you have two `LinkedListNode`s, naming `ElemNode1` and `ElemNode2`, then:

```swift
class Elem {
    var node1 = ElemNode1()
    var node2 = ElemNode2()
    // ...
}
struct ElemNode1: LinkedListNode {
    typealias V = Elem
    var vars = LinkedListNodeVars()
    static let fieldOffset = 0
}
struct ElemNode2: LinkedListNode {
    typealias V = Elem
    var vars = LinkedListNodeVars()
    static let fieldOffset = 16
}
```

### 2. using the `LinkedList`

```swift
// create the list
var ls = LinkedList<ElemNode>()

// add elem into the list
elem.node.addInto(list: &ls)

// foreach
for e in ls.seq() {
    // e is of type Elem
}

// manually traversal
var first = ls.first() // -> E?
var last  = ls.last()  // -> E?
var next  = first!.next(list: &ls) // -> E?

// remove from the list
elem.node.removeSelf()

// insert elem to head of the list
elem.node.insertInto(list: &ls)

// add before or after elem
for e in ls.seq() {
    // insert by element
    elem1.node.add(before: e)
    elem2.node.add(after: e)

    // insert by node
    elem3.node.add(before: e.node)
    elem4.node.add(after: node)
}

// destroy
ls.destroy()
```

## LinkedHashMap

### 1. define data type for `LinkedHashMap`

```swift
struct Key: Hashable {
    var a: UInt32
    var b: UInt16
}

class Value {
    var node = ValueNode()
    var key: Key
    var data: UInt64
    // init(...) { ... }
}

struct ValueNode: LinkedHashMapEntry {
    typealias K = Key
    typealias V = Value

    var vars = LinkedListNodeVars()

    mutating func key() -> Key {
        return element().key
    }

    static let fieldOffset = 0
}
```

Similar to the `ElemNode` for `LinkedList`, you would need to define a `ValueNode` and store the node inside your `Value` class.  
The `LinkedHashMapEntry` inherits `LinkedListNode`, so similar restrictions also apply.

The `key` of the map is usually stored inside the `Value`, so the library provides a helper function `element()` for you to retrieve the `Value` based on the node.

### 2. using the `LinkedHashMap`

```swift
// create the map
var map = LinkedHashMap<ValueNode>(1048576) /* will scale to the next power of 2 number */

// add value into the map
value.node.addInto(map: &map)

// retrieve value from map
let v = map[key]

// remove value from the map
value.node.removeSelf()

// insert value into the map
value.node.insertInto(map: &map)

// destroy
map.destroy()
```

## GeneralLinkedHashMap

### 1. definition

A more general impl is provided, for you to specify your own `LinkedHash` struct.

```swift
// code extracted from `wkgcass/swift-vswitch`, `Conntrack.swift`
public struct GlobalConntrackHash: LinkedHashProtocol {
    private var lock_: RWLockRef?
    var lock: RWLockRef { lock_! }
    public var list: LinkedList<GlobalConnEntryNode>

    public mutating func initStruct() {
        lock_ = RWLockRef()
    }
    // ... other ...
}
```

You could define extra variables or functions here, for example, you could put a `rwlock` here and perform a `per-hash` locking operation.

> However the special logic should be written by yourself.

### 2. using

```swift
var map = GeneralLinkedHashMap<GlobalConntrackHash, GlobalConnEntryNode>()
```

## TimeWheel

A timewheel with custom tick precision and time levels.  
Similar to the above two data structures, you will need to define your own `TimeNode`, and put the `TimeNode` into your own data structure.

### 1. define data type for `TimeWheel`

```swift
class TimeElem {
    var node = TimeElemNode()
    let num: Int

    init(_ num: Int) {
        self.num = num
    }
}

struct TimeElemNode: TimeNode {
    typealias V = TimeElem

    var vars = LinkedListNodeVars()
    var triggerTime: Int64 = 0
    static let fieldOffset: Int = 0

    init() {}
}
```

### 2. using the `TimeWheel`

```swift
// define a timewheel with:
//   1. tick precision is 1sec
//   2. first level has 60 ticks, which means 1 minute
//   3. second level has 60 ticks, which means 1 hour
//   4. third level has 24 ticks, which means 1 day
// the timewheel can safely handle time events 23 hours later after the last `poll()`
// and could handle maximum 24 hours time events
let w = TimeWheelRef<TimeElemNode>(currentTimeMillis: now, precisionMillis: 1000, levelTicks: 60, 60, 24)

let elem1 = TimeElem(1)
elem1.node.triggerTime = now + 120_000 // will trigger after 2 minutes
_ = elem1.node.addInto(wheel: w) // add the time event into timewheel

// get triggered time events
let res = w.poll(currentTimeMillis: now)
// iterate through the triggered time events
for e in ret.list.seq() {
    print(e.num)
}

let elem2 = TimeElem(2)
elem2.node.triggerTime = now + 1000 * 60 * 60 * 24 + 1 // more than 24 hours
let succeeded = elem2.node.addInto(wheel: w) // succeeded == false
```

The result of `poll()` is reference counted, so the time events can be automatically released.  

## NOTE

### LinkedHashMap behavior

The `LinkedHashMap` behavior is not the same as traditional `Dictionary` nor `Map`.  
Multiple entries with the same key could exist at the same time. This is by design.

With this behavior, we don't have to follow the order of removing-then-adding, we could always add the new entry into the map then remove the old one later, without causing any trouble. If we want the new entry to take effect, simply insert the new entry to the head of the hash list, otherwise tail.

This is very useful when we want to overwrite an entry, but the entry's lifecycle is managed by someone else.

### Optimize with `-Ounchecked`

When compiled with `-Ounchecked`, you **MUST** ensure the objects of your value type are actually reference counted.  
In some cases the compiler may think that they are short lived and they could be released without checking the reference counter.

You can use `ENSURE_REFERENCE_COUNTED(elem)` to ensure it's reference counted.

When using the collections, you must make sure `w.destroy()` is called after finished using the collection,
you can store the collections inside a `class`, and destroy them in the `deinit {}` block.
