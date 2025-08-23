//
//  ProvisioningPreviewView.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import ProvisionQLCore
import Quartz
import SwiftUI

struct ProvisioningPreviewView: View {
    let info: ProvisioningInfo?
    let fileURL: URL?

    var body: some View {
        if let info {
            documentContent(for: info)
        } else {
            ProgressView()
        }
    }
}

private extension ProvisioningPreviewView {
    func documentContent(for info: ProvisioningInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Padding.standard) {
                header(for: info)

                OverviewSection(info: info)

                if !info.entitlements.isEmpty {
                    section(title: "Entitlements") {
                        EntitlementsSection(entitlements: info.entitlements)
                    }
                }

                if !info.certificates.isEmpty {
                    section(title: "Certificates (\(info.certificates.count))") {
                        CertificatesSection(certificates: info.certificates)
                    }
                }

                if let devices = info.devices, !devices.isEmpty {
                    section(title: "Devices (\(devices.count))") {
                        DevicesSection(devices: devices)
                    }
                }

                if let fileURL {
                    section(title: "File Info") {
                        FileInfoSection(fileURL: fileURL)
                    }
                }

                footer()
            }
            .padding()
        }
        .frame(minWidth: UIConstants.Window.minWidth, minHeight: UIConstants.Window.minHeight)
    }

    func header(for info: ProvisioningInfo) -> some View {
        ProvisioningProfileHeader(profile: info)
    }

    func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.semibold)
                .font(.title2)

            content()
        }
    }

    func footer() -> some View {
        HStack {
            Text("ProvisionQL \(AppVersion.versionString)")

            #if DEBUG
                Text("(debug)")
            #endif

            Spacer()
        }
        .foregroundColor(.secondary)
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

extension ProvisioningInfo.ProfileType {
    var color: Color {
        switch self {
        case .development: .blue
        case .adHoc: .purple
        case .appStore: UIConstants.Color.validGreen
        case .enterprise: .orange
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, UIConstants.Padding.medium)
            .padding(.vertical, UIConstants.Padding.small)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(UIConstants.CornerRadius.small)
    }
}
