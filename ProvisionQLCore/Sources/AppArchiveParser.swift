//
//  AppArchiveParser.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation
import ZIPFoundation
import Cocoa
import OSLog
import SwiftAXML

public enum AppArchiveParser {
    static let logger = Logger(subsystem: "com.ProvisionQLCore", category: "AppArchiveParser")

    public static func parse(_ url: URL) throws -> AppInfo {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "ipa":
            return try parseIPA(url)
        case "xcarchive":
            return try parseXCArchive(url)
        case "appex":
            return try parseAppExtension(url)
        case "app":
            return try parseApp(url)
        case "apk":
            return try parseAPK(url)
        default:
            throw ParsingError.unsupportedFileType
        }
    }
}

private extension AppArchiveParser {
   static func parseApp(_ url: URL) throws -> AppInfo {
       var isDirectory: ObjCBool = false
       guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
             isDirectory.boolValue
       else {
           throw ParsingError.invalidAppBundle
       }

       let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
       guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
           throw ParsingError.missingInfoPlist
       }

       let plist = try PlistParser.parse(url: infoPlistURL)
       let appInfo = PlistParser.extractAppInfo(from: plist)
       let iconPath = url.appendingPathComponent("Contents/Resources/AppIcon.icns")
       let icon = NSImage(contentsOf: iconPath)
       let embeddedProfile = ProvisioningProfileExtractor.extractFromDirectory(url)
       let entitlements = EntitlementsExtractor.extractEntitlements(from: url)

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
    static func parseIPA(_ url: URL) throws -> AppInfo {
        let fileData = try Data(contentsOf: url)
        let archive = try Archive(data: fileData, accessMode: .read)

        // Find the app bundle path within the archive
        let appBundlePath = try ArchiveUtilities.findAppBundlePath(in: archive, archiveType: .ipa)

        // Extract Info.plist
        let infoPlistPath = appBundlePath + "Info.plist"
        let infoPlistData = try ArchiveUtilities.extractFile(from: archive, path: infoPlistPath)
        let plist = try PlistParser.parse(data: infoPlistData)

        // Parse app information
        let appInfo = PlistParser.extractAppInfo(from: plist)

        // Extract app icon using the dedicated IconExtractor
        let icon = try? IconExtractor.extractIcon(from: url)

        // Extract embedded provisioning profile
        let embeddedProfile = ProvisioningProfileExtractor.extractFromArchive(archive, appBundlePath: appBundlePath)

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
        let plist = try PlistParser.parse(url: infoPlistURL)

        let appInfo = PlistParser.extractAppInfo(from: plist)

        let icon = try? IconExtractor.extractIcon(from: url)

        let embeddedProfile = ProvisioningProfileExtractor.extractFromDirectory(appBundleURL)

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

    static func parseAppExtension(_ url: URL) throws -> AppInfo {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw ParsingError.invalidArchiveFormat
        }

        // Read Info.plist from the extension bundle
        let infoPlistURL = url.appendingPathComponent("Info.plist")
        let plist = try PlistParser.parse(url: infoPlistURL)

        let appInfo = PlistParser.extractAppInfo(from: plist)

        let icon = try? IconExtractor.extractIcon(from: url)

        let embeddedProfile = ProvisioningProfileExtractor.extractFromDirectory(url)

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
        let displayName: String
        if let extensionType = extensionType {
            displayName = "\(appInfo.name) (\(extensionType))"
        } else {
            displayName = appInfo.name
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
            return "Siri Intents"
        case "com.apple.intents-ui-service":
            return "Siri Intents UI"
        case "com.apple.usernotifications.content-extension":
            return "Notification Content"
        case "com.apple.usernotifications.service":
            return "Notification Service"
        case "com.apple.share-services":
            return "Share Extension"
        case "com.apple.widget-extension":
            return "Today Widget"
        case "com.apple.widgetkit-extension":
            return "Widget"
        case "com.apple.keyboard-service":
            return "Keyboard"
        case "com.apple.photo-editing":
            return "Photo Editing"
        case "com.apple.broadcast-services":
            return "Broadcast"
        case "com.apple.callkit.call-directory":
            return "Call Directory"
        case "com.apple.authentication-services-account-authentication-modification-ui":
            return "Account Auth"
        case "com.apple.authentication-services-credential-provider-ui":
            return "Credential Provider"
        case "com.apple.classkit.context-provider":
            return "ClassKit"
        case "com.apple.fileprovider-ui":
            return "File Provider UI"
        case "com.apple.fileprovider-nonui":
            return "File Provider"
        case "com.apple.message-payload-provider":
            return "Messages"
        case "com.apple.networkextension.packet-tunnel":
            return "Packet Tunnel"
        case "com.apple.Safari.content-blocker":
            return "Content Blocker"
        case "com.apple.Safari.web-extension":
            return "Safari Extension"
        default:
            return "App Extension"
        }
    }

    static func extractAppEntitlements(from archive: Archive, appBundlePath: String) -> [String: EntitlementValue] {
        // First, try to find the executable name from Info.plist
        let infoPlistPath = appBundlePath + "Info.plist"
        guard let infoPlistData = try? ArchiveUtilities.extractFile(from: archive, path: infoPlistPath),
              let plist = try? PlistParser.parse(data: infoPlistData),
              let executableName = PlistParser.extractExecutableName(from: plist)
        else {
            return [:]
        }

        // Extract the executable
        let executablePath = appBundlePath + executableName
        guard let executableData = try? ArchiveUtilities.extractFile(from: archive, path: executablePath) else {
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

    static func parseAPK(_ url: URL) throws -> AppInfo {
        let fileData = try Data(contentsOf: url)
        let archive = try Archive(data: fileData, accessMode: .read)

        let manifestPath = "AndroidManifest.xml"
        guard let entry = archive[manifestPath] else {
            throw ParsingError.missingInfoPlist
        }

        var manifestData = Data()
        _ = try archive.extract(entry) { data in
            manifestData.append(data)
        }

        let axml = try AXMLManifestParser(data: manifestData)
        let versionName = axml.version
        let versionCode = axml.buildNumber
        let icon = try? IconExtractor.extractIcon(from: url)

        return AppInfo(
            name: axml.name,
            bundleIdentifier: axml.bundleIdentifier,
            version: versionName,
            buildNumber: versionCode,
            icon: icon,
            embeddedProvisioningProfile: nil,
            entitlements: [:],
            permissions: axml.permissions,
            deviceFamily: [],
            minimumOSVersion: axml.minimumOSVersion,
            sdkVersion: axml.sdkVersion
        )
    }
}
