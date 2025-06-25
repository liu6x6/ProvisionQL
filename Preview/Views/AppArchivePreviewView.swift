//
//  AppArchivePreviewView.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import ProvisionQLCore
import SwiftUI

struct AppArchivePreviewView: View {
    let appInfo: AppInfo
    let fileURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                appHeader()

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Version", value: appInfo.displayVersion)
                        InfoRow(label: "Bundle ID", value: appInfo.bundleIdentifier)

                        if let extensionPointIdentifier = appInfo.extensionPointIdentifier {
                            InfoRow(label: "Extension Point", value: extensionPointIdentifier)
                        }

                        if !appInfo.deviceFamily.isEmpty {
                            InfoRow(label: "Device Family", value: appInfo.deviceFamily.joined(separator: ", "))
                        }

                        if let sdkVersion = appInfo.sdkVersion {
                            Divider()
                            InfoRow(label: "SDK Version", value: sdkVersion)
                        }

                        if let minimumOS = appInfo.minimumOSVersion {
                            InfoRow(label: "Minimum OS", value: minimumOS)
                        }
                    }
                }

                if appInfo.hasEmbeddedProfile, let profile = appInfo.embeddedProvisioningProfile {
                    Divider()
                    embeddedProfileSection(profile: profile)
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
}

private extension AppArchivePreviewView {
    func appHeader() -> some View {
        HStack(alignment: .top, spacing: 16) {
            if let icon = appInfo.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: isAppExtension ? "puzzlepiece.extension" : "app")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appInfo.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text(appInfo.bundleIdentifier)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    func embeddedProfileSection(profile: ProvisioningInfo) -> some View {
        section(title: "Embedded Provisioning Profile") {
            VStack(alignment: .leading, spacing: 12) {
                // Profile header with smaller title
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    ProvisioningProfileHeader(profile: profile, showTitle: false)
                }

                profileContent(for: profile)
            }
        }
    }

    func profileContent(for profile: ProvisioningInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OverviewSection(info: profile)

            if !profile.entitlements.isEmpty {
                section(title: "Entitlements") {
                    EntitlementsSection(entitlements: profile.entitlements)
                }
            }

            if !profile.certificates.isEmpty {
                section(title: "Certificates (\(profile.certificates.count))") {
                    CertificatesSection(certificates: profile.certificates)
                }
            }

            if let devices = profile.devices, !devices.isEmpty {
                section(title: "Devices (\(devices.count))") {
                    DevicesSection(devices: devices)
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
    
    var isAppExtension: Bool {
        guard let fileURL = fileURL else { return false }
        return fileURL.pathExtension.lowercased() == "appex"
    }
}
