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
        }
    }
}
