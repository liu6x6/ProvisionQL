//
//  OverviewSection.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import ProvisionQLCore
import SwiftUI

struct OverviewSection: View {
    let info: ProvisioningInfo

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "UUID", value: info.uuid)
                InfoRow(label: "Team", value: "\(info.teamName) (\(info.teamID))")
                InfoRow(label: "App ID", value: info.appID)
                Divider()
                InfoRow(label: "Created", value: info.creationDate.formatted(date: .long, time: .shortened))
                InfoRow(label: "Expires", value: info.expirationDate.formatted(date: .long, time: .shortened))
                    .foregroundColor(info.expirationStatus.color)
            }
        }
    }
}

extension ExpirationStatus {
    var color: Color {
        switch self {
        case .expired: .red
        case .expiring: .orange
        case .valid: Color(red: 0.0, green: 0.6, blue: 0.0)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.medium)
                .frame(minWidth: 100, alignment: .leading)
                .foregroundColor(.secondary)

            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
