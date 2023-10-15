import Foundation

/// Protocol for supported property values.
public protocol Value {}
extension Int: Value {}
extension Double: Value {}
extension String: Value {}
extension Float: Value {}
extension Bool: Value {}

enum AnyCodableValue: Encodable {
    case integer(Int)
    case string(String)
    case float(Float)
    case double(Double)
    case boolean(Bool)
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .integer(x):
            try container.encode(x)
        case let .string(x):
            try container.encode(x)
        case let .float(x):
            try container.encode(x)
        case let .double(x):
            try container.encode(x)
        case let .boolean(x):
            try container.encode(x)
        case .null:
            try container.encode(self)
        }
    }
}
