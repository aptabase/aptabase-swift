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
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .float(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .boolean(let x):
            try container.encode(x)
        case .null:
            try container.encode(self)
            break
        }
    }
}
