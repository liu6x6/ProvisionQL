//
//  IconExtractor.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import AppKit
import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

public enum IconExtractor {
    public static func extractIcon(from url: URL) throws -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "ipa":
            return try extractFromIPA(url)
        case "xcarchive":
            return try extractFromXCArchive(url)
        case "appex":
            return try extractFromAppBundle(url)
        default:
            return nil
        }
    }
}

private extension IconExtractor {
    static func extractFromIPA(_ url: URL) throws -> NSImage? {
        let archive = try Archive(url: url, accessMode: .read)

        let artworkNames = ["iTunesArtwork@3x", "iTunesArtwork@2x", "iTunesArtwork"]
        for artworkName in artworkNames {
            if let imageData = try ArchiveUtilities.extractFileOptional(from: archive, path: artworkName),
               let image = NSImage(data: imageData)
            {
                return applyRoundedCorners(to: image)
            }
        }

        guard let appBundlePath = ArchiveUtilities.findAppBundlePathFlexible(in: archive) else {
            throw IconExtractionError.appBundleNotFound
        }

        let infoPlistPath = "\(appBundlePath)/Info.plist"
        guard let infoPlistData = try ArchiveUtilities.extractFileOptional(from: archive, path: infoPlistPath) else {
            throw IconExtractionError.infoPlistNotFound
        }

        let plist = try PlistParser.parse(data: infoPlistData)

        if let iconName = findMainIconName(in: plist),
           let image = try findIconInArchive(archive: archive, appBundlePath: appBundlePath, iconName: iconName)
        {
            return applyRoundedCorners(to: image)
        }

        // Try with common prefixes for iOS icons
        let commonPrefixes = ["AppIcon", "Icon"]
        for prefix in commonPrefixes {
            if let image = try findIconInArchive(archive: archive, appBundlePath: appBundlePath, iconName: prefix) {
                return applyRoundedCorners(to: image)
            }
        }

        return nil
    }

    static func extractFromXCArchive(_ url: URL) throws -> NSImage? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw IconExtractionError.appBundleNotFound
        }

        let appsDir = url.appendingPathComponent("Products/Applications")

        // Find the app bundle in Products/Applications/
        let appBundles = try FileManager.default.contentsOfDirectory(at: appsDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "app" }

        guard let appURL = appBundles.first else {
            throw IconExtractionError.appBundleNotFound
        }

        return try extractFromAppBundle(appURL)
    }

    static func extractFromAppBundle(_ url: URL) throws -> NSImage? {
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
        if FileManager.default.fileExists(atPath: infoPlistURL.path) {
            return try extractIconFromBundle(at: url.appendingPathComponent("Contents"), infoPlistURL: infoPlistURL)
        }

        let iOSInfoPlistURL = url.appendingPathComponent("Info.plist")
        if FileManager.default.fileExists(atPath: iOSInfoPlistURL.path) {
            return try extractIconFromBundle(at: url, infoPlistURL: iOSInfoPlistURL)
        }

        return nil
    }

    static func extractIconFromBundle(at bundleURL: URL, infoPlistURL: URL) throws -> NSImage? {
        let plist = try PlistParser.parse(url: infoPlistURL)

        let bundleAction: (String) -> NSImage? = { iconPath in
            let iconURL = bundleURL.appendingPathComponent(iconPath)
            if FileManager.default.fileExists(atPath: iconURL.path) {
                return NSImage(contentsOf: iconURL)
            }
            return nil
        }

        if let iconName = findMainIconName(in: plist),
           let image = findIcon(iconName: iconName, using: bundleAction)
        {
            return applyRoundedCorners(to: image)
        }

        // Try common prefixes as fallback
        let commonPrefixes = ["AppIcon", "Icon"]
        for prefix in commonPrefixes {
            if let image = findIcon(iconName: prefix, using: bundleAction) {
                return applyRoundedCorners(to: image)
            }
        }

        return nil
    }

    // MARK: - Icon Search

    static func findIcon(iconName: String, using action: (String) -> NSImage?) -> NSImage? {
        let deviceSuffixes = ["~tv", "~ipad", ""]
        let sizeExtensions = ["@3x", "@2x", ""]
        let fileExtensions = [".png", ""]

        for deviceSuffix in deviceSuffixes {
            for sizeExt in sizeExtensions {
                for fileExt in fileExtensions {
                    let iconPath = "\(iconName)\(sizeExt)\(deviceSuffix)\(fileExt)"
                    if let image = action(iconPath) {
                        return image
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Icon Name Detection

    static func findMainIconName(in plist: [String: Any]?) -> String? {
        guard let plist else { return nil }

        var allIconFiles: [String] = []

        // Try CFBundleIcons (iOS 5.0+)
        if let bundleIcons = plist["CFBundleIcons"] as? [String: Any],
           let primaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
        {
            allIconFiles.append(contentsOf: iconFiles)
        }

        // Try CFBundleIcons~ipad
        if let bundleIcons = plist["CFBundleIcons~ipad"] as? [String: Any],
           let primaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
        {
            allIconFiles.append(contentsOf: iconFiles)
        }

        // Try CFBundleIcons~tv (tvOS)
        if let bundleIcons = plist["CFBundleIcons~tv"] as? [String: Any],
           let primaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
        {
            allIconFiles.append(contentsOf: iconFiles)
        }

        if !allIconFiles.isEmpty,
           let iconName = findBestIcon(from: allIconFiles)
        {
            return iconName
        }

        // Try CFBundleIconFiles (iOS 3.2+)
        if let iconFiles = plist["CFBundleIconFiles"] as? [String],
           let iconName = findBestIcon(from: iconFiles)
        {
            return iconName
        }

        // Try CFBundleIconFile (legacy)
        if let iconFile = plist["CFBundleIconFile"] as? String {
            return iconFile
        }

        return nil
    }

    static func findBestIcon(from icons: [String]) -> String? {
        let sortedIcons = icons.sorted { icon1, icon2 in
            let size1 = extractSizeFromFilename(icon1)
            let size2 = extractSizeFromFilename(icon2)
            return size1 > size2
        }

        return sortedIcons.first
    }

    static func extractSizeFromFilename(_ filename: String) -> Int {
        let numbers = filename.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers) ?? 0
    }

    // MARK: - Image Processing

    static func applyRoundedCorners(to image: NSImage) -> NSImage {
        let size = image.size
        let cornerRadius = size.width * 0.225

        let newImage = NSImage(size: size)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                                xRadius: cornerRadius,
                                yRadius: cornerRadius)
        path.addClip()

        image.draw(at: .zero,
                   from: NSRect(origin: .zero, size: size),
                   operation: .sourceOver,
                   fraction: 1.0)

        newImage.unlockFocus()
        return newImage
    }

    // MARK: - Archive Helper Methods

    static func findIconInArchive(archive: Archive, appBundlePath: String, iconName: String) throws -> NSImage? {
        let unarchiveAction: (String) -> NSImage? = { iconPath in
            let fullPath = "\(appBundlePath)/\(iconPath)"
            if let imageData = try? ArchiveUtilities.extractFileOptional(from: archive, path: fullPath),
               let image = NSImage(data: imageData)
            {
                return image
            }
            return nil
        }

        return findIcon(iconName: iconName, using: unarchiveAction)
    }
}

// MARK: - Error Types

public enum IconExtractionError: Error {
    case appBundleNotFound
    case infoPlistNotFound
}
