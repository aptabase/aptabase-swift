import XCTest
@testable import Aptabase

final class ConcurrentQueueTests: XCTestCase {
    var concurrentQueue: ConcurrentQueue<Int>!

    override func setUp() {
        super.setUp()
        concurrentQueue = ConcurrentQueue<Int>()
    }

    override func tearDown() {
        concurrentQueue = nil
        super.tearDown()
    }

    func testEnqueueDequeueSingleItem() {
        concurrentQueue.enqueue(42)
        let item = concurrentQueue.dequeue()
        XCTAssertEqual(item, 42)
        XCTAssertTrue(concurrentQueue.isEmpty)
    }

    func testEnqueueDequeueMultipleItems() {
        let itemsToAdd = [1, 2, 3, 4, 5]
        concurrentQueue.enqueue(contentsOf: itemsToAdd)

        let dequeuedItems = concurrentQueue.dequeue(count: itemsToAdd.count)
        XCTAssertEqual(dequeuedItems, itemsToAdd)
        XCTAssertTrue(concurrentQueue.isEmpty)
    }
    
    func testShouldNotThrow() {
        let itemsToAdd = [1, 2, 3, 4, 5]
        concurrentQueue.enqueue(contentsOf: itemsToAdd)

        let dequeuedItems = concurrentQueue.dequeue(count: 10)
        XCTAssertEqual(dequeuedItems, itemsToAdd)
        XCTAssertTrue(concurrentQueue.isEmpty)
    }

    func testIsEmpty() {
        XCTAssertTrue(concurrentQueue.isEmpty)
        concurrentQueue.enqueue(100)
        XCTAssertFalse(concurrentQueue.isEmpty)
        _ = concurrentQueue.dequeue()
        XCTAssertTrue(concurrentQueue.isEmpty)
    }

    func testCount() {
        XCTAssertEqual(concurrentQueue.count, 0)

        let itemsToAdd = [10, 20, 30, 40, 50]
        concurrentQueue.enqueue(contentsOf: itemsToAdd)

        XCTAssertEqual(concurrentQueue.count, itemsToAdd.count)

        _ = concurrentQueue.dequeue(count: 3)
        XCTAssertEqual(concurrentQueue.count, itemsToAdd.count - 3)

        _ = concurrentQueue.dequeue(count: 10)
        XCTAssertEqual(concurrentQueue.count, 0)
    }

    /// Two flushes overlapping is the real-world crash: `EventDispatcher.flush()` runs
    /// from a repeating timer AND from app lifecycle events, so concurrent `dequeue`s
    /// happen in production. Without the barrier both callers read `elements.count`,
    /// then remove past each other's end and trap with
    /// "Fatal error: Array replace: subrange extends past the end".
    func testConcurrentDequeuesDoNotOverRemove() {
        let total = 2_000
        concurrentQueue.enqueue(contentsOf: Array(0 ..< total))
        // Let the barriered enqueue land before draining.
        while concurrentQueue.count < total { usleep(1_000) }

        let drained = NSMutableArray()
        let lock = NSLock()
        let group = DispatchGroup()

        for _ in 0 ..< 8 {
            DispatchQueue.global().async(group: group) {
                while true {
                    let batch = self.concurrentQueue.dequeue(count: 10)
                    if batch.isEmpty { return }
                    lock.lock()
                    drained.addObjects(from: batch)
                    lock.unlock()
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 30), .success)
        XCTAssertEqual(drained.count, total, "every element should be dequeued exactly once")
        XCTAssertEqual(Set(drained as! [Int]).count, total, "no element should be dequeued twice")
        XCTAssertTrue(concurrentQueue.isEmpty)
    }

    /// Same race through the single-element path.
    func testConcurrentSingleDequeuesDoNotOverRemove() {
        let total = 2_000
        concurrentQueue.enqueue(contentsOf: Array(0 ..< total))
        while concurrentQueue.count < total { usleep(1_000) }

        let counter = NSCountedSet()
        let lock = NSLock()
        let group = DispatchGroup()

        for _ in 0 ..< 8 {
            DispatchQueue.global().async(group: group) {
                while let item = self.concurrentQueue.dequeue() {
                    lock.lock()
                    counter.add(item)
                    lock.unlock()
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 30), .success)
        XCTAssertEqual(counter.count, total)
        XCTAssertTrue(concurrentQueue.isEmpty)
    }
}
