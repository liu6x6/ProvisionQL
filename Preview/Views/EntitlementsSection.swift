//
//  EntitlementsSection.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import ProvisionQLCore
import SwiftUI

struct EntitlementsSection: View {
    let entitlements: [String: EntitlementValue]

    var body: some View {
        Text(formattedEntitlements)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
    }
}

private extension EntitlementsSection {
    var sortedEntitlements: [(key: String, value: EntitlementValue)] {
        entitlements.sorted { $0.key < $1.key }
    }

    var formattedEntitlements: String {
        var result = ""

        for (key, value) in sortedEntitlements {
            result += "\(key) = \(formatValue(value))\n"
        }

        return result.trimmingCharacters(in: .newlines)
    }

    func formatValue(_ value: EntitlementValue) -> String {
        switch value {
        case .string(let str):
            return str
        case .bool(let bool):
            return bool ? "true" : "false"
        case .array(let array):
            if array.isEmpty {
                return "()"
            }
            var result = "(\n"
            for item in array {
                result += "    \(item)\n"
            }
            result += ")"
            return result
        case .dictionary(let dict):
            if dict.isEmpty {
                return "{}"
            }
            var result = "{\n"
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                result += "    \(key) = \(value)\n"
            }
            result += "}"
            return result
        }
    }
}
