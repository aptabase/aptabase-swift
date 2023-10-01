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
}
