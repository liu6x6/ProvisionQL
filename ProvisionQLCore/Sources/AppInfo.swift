//
//  AppInfo.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import AppKit
import Foundation

public struct AppInfo {
    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let buildNumber: String
    public let icon: NSImage?
    public let embeddedProvisioningProfile: ProvisioningInfo?
    public let deviceFamily: [String]
    public let minimumOSVersion: String?
    public let sdkVersion: String?

    public init(
        name: String,
        bundleIdentifier: String,
        version: String,
        buildNumber: String,
        icon: NSImage? = nil,
        embeddedProvisioningProfile: ProvisioningInfo? = nil,
        deviceFamily: [String] = [],
        minimumOSVersion: String? = nil,
        sdkVersion: String? = nil
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.buildNumber = buildNumber
        self.icon = icon
        self.embeddedProvisioningProfile = embeddedProvisioningProfile
        self.deviceFamily = deviceFamily
        self.minimumOSVersion = minimumOSVersion
        self.sdkVersion = sdkVersion
    }
}

public extension AppInfo {
    var displayVersion: String {
        if version != buildNumber {
            "\(version) (\(buildNumber))"
        } else {
            version
        }
    }

    var hasEmbeddedProfile: Bool {
        embeddedProvisioningProfile != nil
    }
}
