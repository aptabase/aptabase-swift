import Foundation

protocol URLSessionProtocol {
    func data(for: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

protocol Dispatcher<Item>: Actor where Item: Encodable {
    associatedtype Item

    var maximumBatchSize: Int { get }
    var queue: ConcurrentQueue<Item> { get set }
    var apiUrl: URL { get }
    var headers: [String: String] { get }
    var session: URLSessionProtocol { get }
    var encoder: JSONEncoder { get }

    func enqueue(_ newItem: Item)

    func enqueue(_ newItems: [Item])

    func flush() async

    func sendItems(_ items: [Item]) async throws

    init(appKey: String, baseUrl: String, env: EnvironmentInfo, session: URLSessionProtocol)
}

extension Dispatcher {
    func enqueue(_ newItem: Item) {
        queue.enqueue(newItem)
    }

    func enqueue(_ newItems: [Item]) {
        queue.enqueue(contentsOf: newItems)
    }

    func flush() async {
        if queue.isEmpty {
            return
        }

        var failedItems: [Item] = []
        while !queue.isEmpty {
            let itemsToSend = queue.dequeue(count: maximumBatchSize)
            do {
                try await sendItems(itemsToSend)
            } catch {
                failedItems.append(contentsOf: itemsToSend)
            }
        }

        if !failedItems.isEmpty {
            enqueue(failedItems)
        }
    }
}

/// One encoder per dispatcher: building the date formatter is comparatively expensive, so it must
/// not happen per request.
func makeDispatcherEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.locale = Locale(identifier: "en_US")
    formatter.timeZone = TimeZone(identifier: "UTC")
    encoder.dateEncodingStrategy = .formatted(formatter)
    return encoder
}
