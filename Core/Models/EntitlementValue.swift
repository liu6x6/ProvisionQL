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
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else if let dictValue = try? container.decode([String: String].self) {
            self = .dictionary(dictValue)
        } else {
            throw DecodingError.typeMismatch(
                EntitlementValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported entitlement value type"
                )
            )
        }
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
    static func from(anyCodable: AnyCodable) -> EntitlementValue? {
        if let stringValue = anyCodable.value as? String {
            return .string(stringValue)
        } else if let boolValue = anyCodable.value as? Bool {
            return .bool(boolValue)
        } else if let arrayValue = anyCodable.value as? [String] {
            return .array(arrayValue)
        } else if let dictValue = anyCodable.value as? [String: String] {
            return .dictionary(dictValue)
        }
        return nil
    }
}
