//
//  AppArchiveParser.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation
import ZIPFoundation

public enum AppArchiveParser {
    public static func parse(_ url: URL) throws -> AppInfo {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "ipa":
            return try parseIPA(url)
        case "xcarchive":
            return try parseXCArchive(url)
        case "appex":
            return try parseAppExtension(url)
        default:
            throw ParsingError.unsupportedFileType
        }
    }
}

private extension AppArchiveParser {
    static func parseIPA(_ url: URL) throws -> AppInfo {
        let fileData = try Data(contentsOf: url)
        let archive = try Archive(data: fileData, accessMode: .read)

        // Find the app bundle path within the archive
        let appBundlePath = try findAppBundlePath(in: archive, isIPA: true)

        // Extract Info.plist
        let infoPlistPath = appBundlePath + "Info.plist"
        let infoPlistData = try extractFile(from: archive, path: infoPlistPath)
        let infoPlist = try PropertyListSerialization.propertyList(
            from: infoPlistData,
            options: [],
            format: nil
        ) as? [String: Any]

        guard let plist = infoPlist else {
            throw ParsingError.missingInfoPlist
        }

        // Parse app information
        let appInfo = parseAppInfo(from: plist)

        // Extract app icon using the dedicated IconExtractor
        let icon = try? IconExtractor.extractIcon(from: url)

        // Extract embedded provisioning profile
        let embeddedProfile = extractEmbeddedProvisioningProfile(from: archive, appBundlePath: appBundlePath)

        // Extract app entitlements
        let entitlements = extractAppEntitlements(from: archive, appBundlePath: appBundlePath)

        return AppInfo(
            name: appInfo.name,
            bundleIdentifier: appInfo.bundleIdentifier,
            version: appInfo.version,
            buildNumber: appInfo.buildNumber,
            icon: icon,
            embeddedProvisioningProfile: embeddedProfile,
            entitlements: entitlements,
            deviceFamily: appInfo.deviceFamily,
            minimumOSVersion: appInfo.minimumOSVersion,
            sdkVersion: appInfo.sdkVersion
        )
    }

    static func parseXCArchive(_ url: URL) throws -> AppInfo {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw ParsingError.invalidArchiveFormat
        }

        // Find the app bundle in Products/Applications/
        let productsPath = url.appendingPathComponent("Products/Applications")
        let appBundles = try FileManager.default.contentsOfDirectory(at: productsPath, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "app" }

        guard let appBundleURL = appBundles.first else {
            throw ParsingError.invalidAppBundle
        }

        let infoPlistURL = appBundleURL.appendingPathComponent("Info.plist")
        let infoPlistData = try Data(contentsOf: infoPlistURL)
        let infoPlist = try PropertyListSerialization.propertyList(
            from: infoPlistData,
            options: [],
            format: nil
        ) as? [String: Any]

        guard let plist = infoPlist else {
            throw ParsingError.missingInfoPlist
        }

        let appInfo = parseAppInfo(from: plist)

        let icon = try? IconExtractor.extractIcon(from: url)

        let embeddedProfileURL = appBundleURL.appendingPathComponent("embedded.mobileprovision")
        let embeddedProfile: ProvisioningInfo? = if FileManager.default.fileExists(atPath: embeddedProfileURL.path) {
            try? ProvisioningParser.parse(embeddedProfileURL)
        } else {
            nil
        }

        // Extract app entitlements
        let entitlements = EntitlementsExtractor.extractEntitlements(from: appBundleURL)

        return AppInfo(
            name: appInfo.name,
            bundleIdentifier: appInfo.bundleIdentifier,
            version: appInfo.version,
            buildNumber: appInfo.buildNumber,
            icon: icon,
            embeddedProvisioningProfile: embeddedProfile,
            entitlements: entitlements,
            deviceFamily: appInfo.deviceFamily,
            minimumOSVersion: appInfo.minimumOSVersion,
            sdkVersion: appInfo.sdkVersion
        )
    }

    static func parseAppInfo(from plist: [String: Any]) -> (
        name: String,
        bundleIdentifier: String,
        version: String,
        buildNumber: String,
        deviceFamily: [String],
        minimumOSVersion: String?,
        sdkVersion: String?
    ) {
        let name = plist["CFBundleDisplayName"] as? String ??
            plist["CFBundleName"] as? String ??
            "Unknown App"
        let bundleIdentifier = plist["CFBundleIdentifier"] as? String ?? "Unknown"
        let version = plist["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = plist["CFBundleVersion"] as? String ?? "1"

        // Extract device family and SDK information
        let deviceFamily = extractDeviceFamily(from: plist)
        let minimumOSVersion = extractMinimumOSVersion(from: plist)
        let sdkVersion = extractSDKVersion(from: plist)

        return (
            name: name,
            bundleIdentifier: bundleIdentifier,
            version: version,
            buildNumber: buildNumber,
            deviceFamily: deviceFamily,
            minimumOSVersion: minimumOSVersion,
            sdkVersion: sdkVersion
        )
    }

    static func findAppBundlePath(in archive: Archive, isIPA: Bool) throws -> String {
        if isIPA {
            // Look for Payload/*.app/
            for entry in archive {
                if entry.path.hasPrefix("Payload/"), entry.path.hasSuffix(".app/") {
                    return entry.path
                }
            }
        } else {
            // Look for Products/Applications/*.app/
            for entry in archive {
                if entry.path.hasPrefix("Products/Applications/"), entry.path.hasSuffix(".app/") {
                    return entry.path
                }
            }
        }

        throw ParsingError.invalidAppBundle
    }

    static func extractFile(from archive: Archive, path: String) throws -> Data {
        guard let entry = archive[path] else {
            throw ParsingError.archiveExtractionFailed
        }

        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }

        return data
    }

    static func extractDeviceFamily(from plist: [String: Any]) -> [String] {
        var devices: [String] = []

        if let deviceFamily = plist["UIDeviceFamily"] as? [Int] {
            for family in deviceFamily {
                switch family {
                case 1: devices.append("iPhone")
                case 2: devices.append("iPad")
                case 3: devices.append("Apple TV")
                case 4: devices.append("Apple Watch")
                case 6: devices.append("Mac (Designed for iPad)")
                case 7: devices.append("Apple Vision")
                default: break
                }
            }
        }

        return devices.sorted()
    }

    static func extractMinimumOSVersion(from plist: [String: Any]) -> String? {
        // iOS minimum version
        if let minimumOSVersion = plist["MinimumOSVersion"] as? String {
            return minimumOSVersion
        }

        // macOS minimum version
        if let minimumSystemVersion = plist["LSMinimumSystemVersion"] as? String {
            return minimumSystemVersion
        }

        // watchOS minimum version
        if let minimumWatchOSVersion = plist["WKMinimumWatchOSVersion"] as? String {
            return minimumWatchOSVersion
        }

        return nil
    }

    static func extractSDKVersion(from plist: [String: Any]) -> String? {
        // Check DTSDKName first (more specific)
        if let sdkName = plist["DTSDKName"] as? String {
            return sdkName
        }

        // Check DTSDKBuild
        if let sdkBuild = plist["DTSDKBuild"] as? String {
            return sdkBuild
        }

        // Check DTPlatformVersion
        if let platformVersion = plist["DTPlatformVersion"] as? String {
            return platformVersion
        }

        return nil
    }

    static func parseAppExtension(_ url: URL) throws -> AppInfo {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw ParsingError.invalidArchiveFormat
        }

        // Read Info.plist from the extension bundle
        let infoPlistURL = url.appendingPathComponent("Info.plist")
        let infoPlistData = try Data(contentsOf: infoPlistURL)
        let infoPlist = try PropertyListSerialization.propertyList(
            from: infoPlistData,
            options: [],
            format: nil
        ) as? [String: Any]

        guard let plist = infoPlist else {
            throw ParsingError.missingInfoPlist
        }

        let appInfo = parseAppInfo(from: plist)

        let icon = try? IconExtractor.extractIcon(from: url)

        let embeddedProfileURL = url.appendingPathComponent("embedded.mobileprovision")
        let embeddedProfile: ProvisioningInfo? = if FileManager.default.fileExists(atPath: embeddedProfileURL.path) {
            try? ProvisioningParser.parse(embeddedProfileURL)
        } else {
            nil
        }

        // Extract extension type from NSExtension dictionary
        var extensionType: String?
        var extensionPointIdentifier: String?
        if let nsExtension = plist["NSExtension"] as? [String: Any],
           let identifier = nsExtension["NSExtensionPointIdentifier"] as? String
        {
            extensionPointIdentifier = identifier
            extensionType = parseExtensionType(from: identifier)
        }

        // For app extensions, append the extension type to the name
        let displayName = if let extensionType {
            "\(appInfo.name) (\(extensionType))"
        } else {
            appInfo.name
        }

        // Extract app entitlements
        let entitlements = EntitlementsExtractor.extractEntitlements(from: url)

        return AppInfo(
            name: displayName,
            bundleIdentifier: appInfo.bundleIdentifier,
            version: appInfo.version,
            buildNumber: appInfo.buildNumber,
            icon: icon,
            embeddedProvisioningProfile: embeddedProfile,
            entitlements: entitlements,
            deviceFamily: appInfo.deviceFamily,
            minimumOSVersion: appInfo.minimumOSVersion,
            sdkVersion: appInfo.sdkVersion,
            extensionPointIdentifier: extensionPointIdentifier
        )
    }

    static func parseExtensionType(from identifier: String) -> String {
        switch identifier {
        case "com.apple.intents-service":
            "Siri Intents"
        case "com.apple.intents-ui-service":
            "Siri Intents UI"
        case "com.apple.usernotifications.content-extension":
            "Notification Content"
        case "com.apple.usernotifications.service":
            "Notification Service"
        case "com.apple.share-services":
            "Share Extension"
        case "com.apple.widget-extension":
            "Today Widget"
        case "com.apple.widgetkit-extension":
            "Widget"
        case "com.apple.keyboard-service":
            "Keyboard"
        case "com.apple.photo-editing":
            "Photo Editing"
        case "com.apple.broadcast-services":
            "Broadcast"
        case "com.apple.callkit.call-directory":
            "Call Directory"
        case "com.apple.authentication-services-account-authentication-modification-ui":
            "Account Auth"
        case "com.apple.authentication-services-credential-provider-ui":
            "Credential Provider"
        case "com.apple.classkit.context-provider":
            "ClassKit"
        case "com.apple.fileprovider-ui":
            "File Provider UI"
        case "com.apple.fileprovider-nonui":
            "File Provider"
        case "com.apple.message-payload-provider":
            "Messages"
        case "com.apple.networkextension.packet-tunnel":
            "Packet Tunnel"
        case "com.apple.Safari.content-blocker":
            "Content Blocker"
        case "com.apple.Safari.web-extension":
            "Safari Extension"
        default:
            "App Extension"
        }
    }

    static func extractEmbeddedProvisioningProfile(from archive: Archive, appBundlePath: String) -> ProvisioningInfo? {
        let profilePath = appBundlePath + "embedded.mobileprovision"

        guard let profileData = try? extractFile(from: archive, path: profilePath) else {
            return nil
        }

        // Create a temporary file to parse the provisioning profile
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mobileprovision")

        do {
            try profileData.write(to: tempURL)
            let provisioningInfo = try ProvisioningParser.parse(tempURL)
            try FileManager.default.removeItem(at: tempURL)
            return provisioningInfo
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    static func extractAppEntitlements(from archive: Archive, appBundlePath: String) -> [String: EntitlementValue] {
        // First, try to find the executable name from Info.plist
        let infoPlistPath = appBundlePath + "Info.plist"
        guard let infoPlistData = try? extractFile(from: archive, path: infoPlistPath),
              let infoPlist = try? PropertyListSerialization.propertyList(
                  from: infoPlistData,
                  options: [],
                  format: nil
              ) as? [String: Any],
              let executableName = infoPlist["CFBundleExecutable"] as? String
        else {
            return [:]
        }

        // Extract the executable
        let executablePath = appBundlePath + executableName
        guard let executableData = try? extractFile(from: archive, path: executablePath) else {
            return [:]
        }

        // Use the EntitlementsExtractor with temporary directory
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDirectory) }

            return EntitlementsExtractor.extractEntitlementsFromArchive(
                executableData: executableData,
                temporaryDirectory: tempDirectory
            )
        } catch {
            return [:]
        }
    }
}
