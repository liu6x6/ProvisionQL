//
//  ParsingError.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation

public enum ParsingError: Error, LocalizedError {
    case cmsDecodingFailed
    case plistExtractionFailed
    case invalidFileFormat
    case invalidProvisioningProfile
    case archiveExtractionFailed
    case missingInfoPlist
    case invalidAppBundle
    case unsupportedFileType
    case invalidArchiveFormat

    public var errorDescription: String? {
        switch self {
        case .cmsDecodingFailed:
            "Failed to decode CMS data from provisioning profile"
        case .plistExtractionFailed:
            "Failed to extract property list data"
        case .invalidFileFormat:
            "Invalid file format"
        case .invalidProvisioningProfile:
            "Invalid provisioning profile"
        case .archiveExtractionFailed:
            "Failed to extract files from archive"
        case .missingInfoPlist:
            "Missing Info.plist in app bundle"
        case .invalidAppBundle:
            "Invalid app bundle structure"
        case .unsupportedFileType:
            "Unsupported file type"
        case .invalidArchiveFormat:
            "Invalid archive format"
        }
    }
}
