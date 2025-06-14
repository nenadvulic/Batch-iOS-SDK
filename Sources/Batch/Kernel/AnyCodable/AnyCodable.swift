import Foundation

/**
 A type-erased `Codable` value.

 The `AnyCodable` type forwards encoding and decoding responsibilities
 to an underlying value, hiding its specific underlying type.

 You can encode or decode mixed-type values in dictionaries
 by declaring their contained type to be `AnyCodable`.

 */
@frozen public struct AnyCodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable: Codable {
    // MARK: -

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            #if canImport(Foundation)
                self.init(NSNull())
            #else
                self.init(Self?.none)
            #endif
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map(\.value))
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value cannot be decoded")
        }
    }

    // MARK: -

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
                case let number as NSNumber:
                    try encode(nsnumber: number, into: &container)
            #endif
            #if canImport(Foundation)
                case is NSNull:
                    try container.encodeNil()
            #endif
            case is Void:
                try container.encodeNil()
            case let bool as Bool:
                try container.encode(bool)
            case let int as Int:
                try container.encode(int)
            case let int8 as Int8:
                try container.encode(int8)
            case let int16 as Int16:
                try container.encode(int16)
            case let int32 as Int32:
                try container.encode(int32)
            case let int64 as Int64:
                try container.encode(int64)
            case let uint as UInt:
                try container.encode(uint)
            case let uint8 as UInt8:
                try container.encode(uint8)
            case let uint16 as UInt16:
                try container.encode(uint16)
            case let uint32 as UInt32:
                try container.encode(uint32)
            case let uint64 as UInt64:
                try container.encode(uint64)
            case let float as Float:
                try container.encode(float)
            case let double as Double:
                try container.encode(double)
            case let string as String:
                try container.encode(string)
            #if canImport(Foundation)
                case let date as Date:
                    try container.encode(date)
                case let url as URL:
                    try container.encode(url)
            #endif
            case let array as [Any?]:
                try container.encode(array.map { AnyCodable($0) })
            case let dictionary as [String: Any?]:
                try container.encode(dictionary.mapValues { AnyCodable($0) })
            default:
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyEncodable value cannot be encoded")
                throw EncodingError.invalidValue(value, context)
        }
    }

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        private func encode(nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
            switch CFNumberGetType(nsnumber) {
                case .charType:
                    try container.encode(nsnumber.boolValue)
                case .sInt8Type:
                    try container.encode(nsnumber.int8Value)
                case .sInt16Type:
                    try container.encode(nsnumber.int16Value)
                case .sInt32Type:
                    try container.encode(nsnumber.int32Value)
                case .sInt64Type:
                    try container.encode(nsnumber.int64Value)
                case .shortType:
                    try container.encode(nsnumber.uint16Value)
                case .longType:
                    try container.encode(nsnumber.uint32Value)
                case .longLongType:
                    try container.encode(nsnumber.uint64Value)
                case .intType, .nsIntegerType, .cfIndexType:
                    try container.encode(nsnumber.intValue)
                case .floatType, .float32Type:
                    try container.encode(nsnumber.floatValue)
                case .doubleType, .float64Type, .cgFloatType:
                    try container.encode(nsnumber.doubleValue)
                #if swift(>=5.0)
                    @unknown default:
                        let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "NSNumber cannot be encoded because its type is not handled")
                        throw EncodingError.invalidValue(nsnumber, context)
                #endif
            }
        }
    #endif
}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
            case is (Void, Void):
                return true
            case let (lhs as Bool, rhs as Bool):
                return lhs == rhs
            case let (lhs as Int, rhs as Int):
                return lhs == rhs
            case let (lhs as Int8, rhs as Int8):
                return lhs == rhs
            case let (lhs as Int16, rhs as Int16):
                return lhs == rhs
            case let (lhs as Int32, rhs as Int32):
                return lhs == rhs
            case let (lhs as Int64, rhs as Int64):
                return lhs == rhs
            case let (lhs as UInt, rhs as UInt):
                return lhs == rhs
            case let (lhs as UInt8, rhs as UInt8):
                return lhs == rhs
            case let (lhs as UInt16, rhs as UInt16):
                return lhs == rhs
            case let (lhs as UInt32, rhs as UInt32):
                return lhs == rhs
            case let (lhs as UInt64, rhs as UInt64):
                return lhs == rhs
            case let (lhs as Float, rhs as Float):
                return lhs == rhs
            case let (lhs as Double, rhs as Double):
                return lhs == rhs
            case let (lhs as String, rhs as String):
                return lhs == rhs
            case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
                return lhs == rhs
            case let (lhs as [AnyCodable], rhs as [AnyCodable]):
                return lhs == rhs
            case let (lhs as [String: Any], rhs as [String: Any]):
                return NSDictionary(dictionary: lhs) == NSDictionary(dictionary: rhs)
            case let (lhs as [Any], rhs as [Any]):
                return NSArray(array: lhs) == NSArray(array: rhs)
            case is (NSNull, NSNull):
                return true
            default:
                return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
            case is Void:
                return String(describing: nil as Any?)
            case let value as CustomStringConvertible:
                return value.description
            default:
                return String(describing: value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
            case let value as CustomDebugStringConvertible:
                return "AnyCodable(\(value.debugDescription))"
            default:
                return "AnyCodable(\(description))"
        }
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }
}

extension AnyCodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
            case let value as Bool:
                hasher.combine(value)
            case let value as Int:
                hasher.combine(value)
            case let value as Int8:
                hasher.combine(value)
            case let value as Int16:
                hasher.combine(value)
            case let value as Int32:
                hasher.combine(value)
            case let value as Int64:
                hasher.combine(value)
            case let value as UInt:
                hasher.combine(value)
            case let value as UInt8:
                hasher.combine(value)
            case let value as UInt16:
                hasher.combine(value)
            case let value as UInt32:
                hasher.combine(value)
            case let value as UInt64:
                hasher.combine(value)
            case let value as Float:
                hasher.combine(value)
            case let value as Double:
                hasher.combine(value)
            case let value as String:
                hasher.combine(value)
            case let value as [String: AnyCodable]:
                hasher.combine(value)
            case let value as [AnyCodable]:
                hasher.combine(value)
            default:
                break
        }
    }
}
