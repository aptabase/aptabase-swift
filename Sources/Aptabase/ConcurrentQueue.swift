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
        queue.sync {
            if !self.elements.isEmpty {
                result = self.elements.removeFirst()
            }
        }
        return result
    }

    func dequeue(count: Int) -> [T] {
        var dequeuedElements = [T]()
        queue.sync {
            for _ in 0..<min(count, self.elements.count) {
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
