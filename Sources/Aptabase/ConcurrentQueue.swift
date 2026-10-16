import Foundation

class ConcurrentQueue<T> {
    private var queue = DispatchQueue(label: "com.aptabase.ConcurrentQueue", attributes: .concurrent)
    private var elements = [T]()

    func enqueue(_ element: T) {
        queue.async(flags: .barrier) {
            self.elements.append(element)
        }
    }

    func enqueue(contentsOf newElements: [T]) {
        queue.async(flags: .barrier) {
            self.elements.append(contentsOf: newElements)
        }
    }

    func dequeue() -> T? {
        var result: T?
        // Mutation needs the barrier: on a concurrent queue a plain `sync` runs
        // alongside other readers and dequeues, so two callers can both see a
        // non-empty array and both `removeFirst()`.
        queue.sync(flags: .barrier) {
            if !self.elements.isEmpty {
                result = self.elements.removeFirst()
            }
        }
        return result
    }

    func dequeue(count: Int) -> [T] {
        var dequeuedElements = [T]()
        // Mutation needs the barrier — see `dequeue()`. Without it two overlapping
        // flushes each read `elements.count`, then remove past each other's end and
        // trap with "Array replace: subrange extends past the end".
        queue.sync(flags: .barrier) {
            for _ in 0 ..< min(count, self.elements.count) {
                dequeuedElements.append(self.elements.removeFirst())
            }
        }
        return dequeuedElements
    }

    var isEmpty: Bool {
        var empty = true
        queue.sync {
            empty = self.elements.isEmpty
        }
        return empty
    }

    var count: Int {
        var count = 0
        queue.sync {
            count = self.elements.count
        }
        return count
    }
}
