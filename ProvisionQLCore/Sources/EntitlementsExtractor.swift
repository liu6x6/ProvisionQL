//
//  EntitlementsExtractor.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation
import Security

public enum EntitlementsExtractor {
    public static func extractEntitlements(from appBundleURL: URL) -> [String: EntitlementValue] {
        extractEntitlementsUsingSecCode(from: appBundleURL) ?? [:]
    }

    static func extractEntitlementsFromArchive(
        executableData: Data,
        temporaryDirectory: URL
    ) -> [String: EntitlementValue] {
        // Write executable to temporary file
        let tempExecutableURL = temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try executableData.write(to: tempExecutableURL)
            defer { try? FileManager.default.removeItem(at: tempExecutableURL) }

            // Make it executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: tempExecutableURL.path
            )

            return extractEntitlementsUsingSecCode(from: tempExecutableURL) ?? [:]
        } catch {
            return [:]
        }
    }
}

private extension EntitlementsExtractor {
    static func extractEntitlementsUsingSecCode(from codeURL: URL) -> [String: EntitlementValue]? {
        var staticCode: SecStaticCode?
        var status = SecStaticCodeCreateWithPath(codeURL as CFURL, [], &staticCode)

        guard status == errSecSuccess, let staticCode else {
            return nil
        }

        var signature: CFDictionary?
        status = SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &signature)

        guard status == errSecSuccess, let signature else {
            return nil
        }

        let signatureDict = signature as NSDictionary

        // Extract entitlements from the signing information
        guard let entitlementsData = signatureDict[kSecCodeInfoEntitlementsDict as String] as? [String: Any] else {
            return nil
        }

        var entitlements: [String: EntitlementValue] = [:]

        for (key, value) in entitlementsData {
            if let stringValue = value as? String {
                entitlements[key] = .string(stringValue)
            } else if let boolValue = value as? Bool {
                entitlements[key] = .bool(boolValue)
            } else if let arrayValue = value as? [String] {
                entitlements[key] = .array(arrayValue)
            } else if let arrayValue = value as? [Any] {
                // Convert array of any to array of strings
                let stringArray = arrayValue.compactMap { "\($0)" }
                if !stringArray.isEmpty {
                    entitlements[key] = .array(stringArray)
                }
            } else if let dictValue = value as? [String: String] {
                entitlements[key] = .dictionary(dictValue)
            } else if let dictValue = value as? [String: Any] {
                // Convert dict values to strings
                var stringDict: [String: String] = [:]
                for (k, v) in dictValue {
                    stringDict[k] = "\(v)"
                }
                if !stringDict.isEmpty {
                    entitlements[key] = .dictionary(stringDict)
                }
            }
        }

        return entitlements
    }
}
