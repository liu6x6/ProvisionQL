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
        
        var appName = axml.name
        if appName.hasPrefix("@"), let resId = UInt32(appName.dropFirst(), radix: 16) {
            if let entry = archive["resources.arsc"] {
                var arscData = Data()
                _ = try? archive.extract(entry) { data in
                    arscData.append(data)
                }
                if let resolvedName = readARSC(data: arscData, targetResId: resId) {
                    appName = resolvedName
                }
            }
        }

        return AppInfo(
            name: appName,
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

// MARK: - ARSC Parsing Utilities for App Name Extraction

private struct StringPool {
    let data: Data
    let stringCount: Int
    let flags: UInt32
    var stringsStart: Int
    let offsets: [UInt32]

    init?(data: Data, offset: Int) {
        self.data = data
        let type = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt16.self).littleEndian }
        guard type == 0x0001 else { return nil } // RES_STRING_POOL_TYPE
        
        let headerSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 2, as: UInt16.self).littleEndian })
        
        stringCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self).littleEndian })
        flags = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self).littleEndian }
        stringsStart = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 20, as: UInt32.self).littleEndian })
        
        var offs = [UInt32]()
        var cur = offset + headerSize
        for _ in 0..<stringCount {
            offs.append(data.withUnsafeBytes { $0.load(fromByteOffset: cur, as: UInt32.self).littleEndian })
            cur += 4
        }
        self.offsets = offs
        self.stringsStart += offset // absolute
    }

    func getString(at index: Int) -> String? {
        guard index >= 0 && index < stringCount else { return nil }
        let strOffset = stringsStart + Int(offsets[index])
        
        let isUTF8 = (flags & (1 << 8)) != 0
        
        if isUTF8 {
            var cur = strOffset
            let len1 = data[cur]; cur += 1
            if (len1 & 0x80) != 0 { cur += 1 }
            let len2 = data[cur]; cur += 1
            var realLen = Int(len2)
            if (len2 & 0x80) != 0 {
                let len3 = data[cur]; cur += 1
                realLen = ((Int(len2) & 0x7F) << 8) | Int(len3)
            }
            let strData = data.subdata(in: cur..<(cur + realLen))
            return String(data: strData, encoding: .utf8)
        } else {
            var cur = strOffset
            let len1 = data.withUnsafeBytes { $0.load(fromByteOffset: cur, as: UInt16.self).littleEndian }; cur += 2
            var realLen = Int(len1)
            if (len1 & 0x8000) != 0 {
                let len2 = data.withUnsafeBytes { $0.load(fromByteOffset: cur, as: UInt16.self).littleEndian }; cur += 2
                realLen = ((Int(len1) & 0x7FFF) << 16) | Int(len2)
            }
            let strData = data.subdata(in: cur..<(cur + realLen * 2))
            return String(data: strData, encoding: .utf16LittleEndian)
        }
    }
}

private func readARSC(data: Data, targetResId: UInt32) -> String? {
    guard data.count > 12 else { return nil }
    var cursor = 0
    let type = data.withUnsafeBytes { $0.load(fromByteOffset: cursor, as: UInt16.self).littleEndian }
    guard type == 0x0002 else { return nil } // RES_TABLE_TYPE
    
    let headerSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 2, as: UInt16.self).littleEndian })
    let packageCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 8, as: UInt32.self).littleEndian })
    
    cursor += headerSize
    
    let globalPoolType = data.withUnsafeBytes { $0.load(fromByteOffset: cursor, as: UInt16.self).littleEndian }
    var globalPool: StringPool? = nil
    if globalPoolType == 0x0001 {
        let poolSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 4, as: UInt32.self).littleEndian })
        globalPool = StringPool(data: data, offset: cursor)
        cursor += poolSize
    }
    
    let targetPP = (targetResId >> 24) & 0xFF
    let targetTT = (targetResId >> 16) & 0xFF
    let targetEEEE = targetResId & 0xFFFF
    
    var foundValues: [String: String] = [:] // locale -> string

    var currentPackageIndex = 0
    while cursor + 8 <= data.count && currentPackageIndex < packageCount {
        let pType = data.withUnsafeBytes { $0.load(fromByteOffset: cursor, as: UInt16.self).littleEndian }
        let pHeaderSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 2, as: UInt16.self).littleEndian })
        let pSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 4, as: UInt32.self).littleEndian })
        
        if pType == 0x0200 { // RES_TABLE_PACKAGE_TYPE
            let id = data.withUnsafeBytes { $0.load(fromByteOffset: cursor + 8, as: UInt32.self).littleEndian }
            
            if id == targetPP {
                var pCursor = cursor + pHeaderSize
                let pEnd = cursor + pSize
                
                while pCursor + 8 <= pEnd {
                    let chunkType = data.withUnsafeBytes { $0.load(fromByteOffset: pCursor, as: UInt16.self).littleEndian }
                    let chunkHeaderSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 2, as: UInt16.self).littleEndian })
                    let chunkSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 4, as: UInt32.self).littleEndian })
                    
                    if chunkType == 0x0201 { // RES_TABLE_TYPE_TYPE
                        let tId = data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 8, as: UInt8.self) }
                        if tId == targetTT {
                            let entryCount = Int(data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 12, as: UInt32.self).littleEndian })
                            let entriesStart = Int(data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 16, as: UInt32.self).littleEndian })
                            
                            let configSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: pCursor + 20, as: UInt32.self).littleEndian })
                            var lang = ""
                            var country = ""
                            if configSize >= 8 {
                                let l1 = data[pCursor + 20 + 4], l2 = data[pCursor + 20 + 5]
                                if l1 != 0 { lang = String(bytes: [l1, l2].filter { $0 != 0 }, encoding: .ascii) ?? "" }
                                let c1 = data[pCursor + 20 + 6], c2 = data[pCursor + 20 + 7]
                                if c1 != 0 { country = String(bytes: [c1, c2].filter { $0 != 0 }, encoding: .ascii) ?? "" }
                            }
                            let locale = lang.isEmpty ? "default" : (country.isEmpty ? lang : "\(lang)-\(country)")
                            
                            if targetEEEE < entryCount {
                                let offsetOffset = pCursor + chunkHeaderSize + Int(targetEEEE * 4)
                                let entryOffset = data.withUnsafeBytes { $0.load(fromByteOffset: offsetOffset, as: UInt32.self).littleEndian }
                                
                                if entryOffset != 0xFFFFFFFF {
                                    let entryCursor = pCursor + entriesStart + Int(entryOffset)
                                    if entryCursor + 8 <= data.count {
                                        let flags = data.withUnsafeBytes { $0.load(fromByteOffset: entryCursor + 2, as: UInt16.self).littleEndian }
                                        let isComplex = (flags & 0x0001) != 0
                                        
                                        if !isComplex {
                                            let size = Int(data.withUnsafeBytes { $0.load(fromByteOffset: entryCursor, as: UInt16.self).littleEndian })
                                            let valueCursor = entryCursor + size
                                            if valueCursor + 8 <= data.count {
                                                let dataType = data[valueCursor + 3]
                                                let dataVal = Int(data.withUnsafeBytes { $0.load(fromByteOffset: valueCursor + 4, as: UInt32.self).littleEndian })
                                                
                                                if dataType == 0x03 { // TYPE_STRING
                                                    if let str = globalPool?.getString(at: dataVal) {
                                                        foundValues[locale] = str
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    pCursor += chunkSize
                }
            }
        }
        cursor += pSize
        currentPackageIndex += 1
    }
    
    // We prefer Chinese/English based on common locales, fallback to default
    let preferredLocales = ["zh-CN", "zh", "en-US", "en", "default"]
    for loc in preferredLocales {
        if let val = foundValues[loc] {
            return val
        }
    }
    
    return foundValues.values.first
}
