//
//  ProvisioningProfileExtractor.swift
//  ProvisionQLCore
//
//  Created by Evgeny Aleksandrov

import Foundation
import ZIPFoundation

/// Utilities for extracting embedded provisioning profiles
enum ProvisioningProfileExtractor {
    private static let embeddedProvisioningProfileName = "embedded.mobileprovision"

    // MARK: - Archive Extraction

    /// Extracts an embedded provisioning profile from an archive
    /// - Parameters:
    ///   - archive: The ZIP archive
    ///   - appBundlePath: The path to the app bundle within the archive
    /// - Returns: The provisioning info if found and successfully parsed
    static func extractFromArchive(_ archive: Archive, appBundlePath: String) -> ProvisioningInfo? {
        let profilePath = appBundlePath + embeddedProvisioningProfileName

        guard let profileData = try? ArchiveUtilities.extractFile(from: archive, path: profilePath) else {
            return nil
        }

        // Create a temporary file to parse the provisioning profile
        let tempURL = createTemporaryURL()

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

    // MARK: - Directory Extraction

    /// Extracts an embedded provisioning profile from a directory
    /// - Parameter directoryURL: The URL to the app bundle directory
    /// - Returns: The provisioning info if found and successfully parsed
    static func extractFromDirectory(_ directoryURL: URL) -> ProvisioningInfo? {
        let profileURL = directoryURL.appendingPathComponent(embeddedProvisioningProfileName)

        guard FileManager.default.fileExists(atPath: profileURL.path) else {
            return nil
        }

        return try? ProvisioningParser.parse(profileURL)
    }

    // MARK: - Helper Methods

    /// Creates a temporary URL for storing provisioning profile data
    private static func createTemporaryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mobileprovision")
    }
}
