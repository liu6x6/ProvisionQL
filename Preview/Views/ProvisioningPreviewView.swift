//
//  ProvisioningPreviewView.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import Core
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
            VStack(alignment: .leading, spacing: 12) {
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
        .frame(minWidth: 600, minHeight: 400)
    }

    func header(for info: ProvisioningInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(info.name)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                StatusBadge(
                    text: info.platform.map(\.rawValue).joined(separator: ", "),
                    color: .blue
                )

                StatusBadge(
                    text: info.profileType.rawValue,
                    color: info.profileType.color
                )

                StatusBadge(
                    text: info.expirationStatus.rawValue,
                    color: info.expirationStatus.color
                )

                if !info.certificates.isEmpty {
                    StatusBadge(
                        text: "\(info.certificates.count) certs",
                        color: .indigo
                    )
                }

                if let deviceCount = info.devices?.count {
                    StatusBadge(
                        text: "\(deviceCount) devices",
                        color: .indigo
                    )
                }
            }
        }
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
            Text("ProvisionQL \(versionString)")

            #if DEBUG
                Text("(debug)")
            #endif

            Spacer()
        }
        .foregroundColor(.secondary)
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }

    var versionString: String {
        let bundle = Bundle(for: PreviewViewController.self)
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "v\(version) (\(build))"
    }
}

extension ProvisioningInfo.ProfileType {
    var color: Color {
        switch self {
        case .development: .blue
        case .adHoc: .purple
        case .appStore: Color(red: 0.0, green: 0.6, blue: 0.0)
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
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
