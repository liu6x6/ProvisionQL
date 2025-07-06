//
//  EntitlementValue.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation

@frozen
public enum EntitlementValue: Sendable, Codable, Hashable {
    case string(String)
    case bool(Bool)
    case array([String])
    case dictionary([String: String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try string first (most common)
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }

        // Try bool
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }

        // Try array of strings
        if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
            return
        }

        // Try dictionary of strings
        if let dictValue = try? container.decode([String: String].self) {
            self = .dictionary(dictValue)
            return
        }

        // Handle numeric types by converting to string
        if let intValue = try? container.decode(Int.self) {
            self = .string(String(intValue))
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            self = .string(String(doubleValue))
            return
        }

        throw DecodingError.typeMismatch(
            EntitlementValue.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported entitlement value type"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}

extension EntitlementValue {
    /// Converts Any value to EntitlementValue, handling type conversion as needed
    static func from(value: Any) -> EntitlementValue? {
        switch value {
        case let stringValue as String:
            return .string(stringValue)
        case let boolValue as Bool:
            return .bool(boolValue)
        case let arrayValue as [String]:
            return .array(arrayValue)
        case let dictValue as [String: String]:
            return .dictionary(dictValue)
        case let intValue as Int:
            return .string(String(intValue))
        case let doubleValue as Double:
            return .string(String(doubleValue))
        case let mixedArray as [Any]:
            // Convert mixed array to string array
            let stringArray = mixedArray.compactMap { item -> String? in
                switch item {
                case let stringValue as String:
                    return stringValue
                case let boolValue as Bool:
                    return String(boolValue)
                case let intValue as Int:
                    return String(intValue)
                case let doubleValue as Double:
                    return String(doubleValue)
                default:
                    return nil
                }
            }
            return .array(stringArray)
        case let mixedDict as [String: Any]:
            // Convert mixed dictionary to string dictionary
            let stringDict = mixedDict.compactMapValues { item -> String? in
                switch item {
                case let stringValue as String:
                    return stringValue
                case let boolValue as Bool:
                    return String(boolValue)
                case let intValue as Int:
                    return String(intValue)
                case let doubleValue as Double:
                    return String(doubleValue)
                default:
                    return nil
                }
            }
            return .dictionary(stringDict)
        default:
            return nil
        }
    }
}
