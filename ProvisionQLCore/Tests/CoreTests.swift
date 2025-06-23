//
//  CoreTests.swift
//  CoreTests
//
//  Created by Evgeny Aleksandrov

import Foundation
@testable import ProvisionQLCore
import Testing

// MARK: - Tags

extension Tag {
    @Tag static var badgeInfo: Self
    @Tag static var provisioningInfo: Self
    @Tag static var parser: Self
    @Tag static var models: Self
    @Tag static var expiration: Self
}

// MARK: - Test Suites

@Suite("Core Framework Tests")
struct CoreTests {
    @Suite("BadgeInfo Tests", .tags(.badgeInfo, .models))
    struct BadgeInfoTests {
        @Test("BadgeInfo initialization with parameters")
        func badgeInfoInitialization() {
            let badgeInfo = BadgeInfo(
                deviceCount: 5,
                expirationStatus: .valid,
                profileType: .development
            )

            #expect(badgeInfo.deviceCount == 5)
            #expect(badgeInfo.expirationStatus == .valid)
            #expect(badgeInfo.profileType == .development)
        }

        @Test("BadgeInfo creation from ProvisioningInfo")
        func badgeInfoFromProvisioningInfo() throws {
            let mockProfile = RawProfile(
                UUID: "12345678-1234-1234-1234-123456789ABC",
                Name: "Test Profile",
                TeamName: "Test Team",
                TeamIdentifier: ["ABC123"],
                AppIDName: "Test App",
                Entitlements: ["get-task-allow": AnyCodable(true)],
                ExpirationDate: Date().addingTimeInterval(86400 * 60), // 60 days from now
                CreationDate: Date(),
                DeveloperCertificates: nil,
                ProvisionedDevices: ["device1", "device2", "device3"],
                ProvisionsAllDevices: false,
                Platform: ["iOS"]
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)
            let badgeInfo = BadgeInfo(from: provisioningInfo)

            #expect(badgeInfo.deviceCount == 3)
            #expect(badgeInfo.expirationStatus == .valid)
            #expect(badgeInfo.profileType == .development)
        }

        @Test("BadgeInfo with zero devices")
        func badgeInfoZeroDevices() throws {
            let mockProfile = RawProfile(
                UUID: "87654321-4321-4321-4321-ABCDEF123456",
                Name: "App Store Profile",
                TeamName: "Test Team",
                TeamIdentifier: ["ABC123"],
                AppIDName: "Test App",
                Entitlements: [:],
                ExpirationDate: Date().addingTimeInterval(86400 * 60),
                CreationDate: Date(),
                DeveloperCertificates: nil,
                ProvisionedDevices: nil,
                ProvisionsAllDevices: false,
                Platform: ["iOS"]
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)
            let badgeInfo = BadgeInfo(from: provisioningInfo)

            #expect(badgeInfo.deviceCount == 0)
            #expect(badgeInfo.profileType == .appStore)
        }
    }

    @Suite("ProvisioningInfo Tests", .tags(.provisioningInfo, .models))
    struct ProvisioningInfoTests {
        @Test("ProvisioningInfo initialization from RawProfile")
        func provisioningInfoInitialization() throws {
            let expirationDate = Date().addingTimeInterval(86400 * 45) // 45 days from now
            let creationDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago

            let mockProfile = RawProfile(
                UUID: "ABCDEF12-3456-7890-ABCD-EF1234567890",
                Name: "Test Development Profile",
                TeamName: "Test Team LLC",
                TeamIdentifier: ["ABCD123456"],
                AppIDName: "My Test App",
                Entitlements: [
                    "get-task-allow": AnyCodable(true),
                    "application-identifier": AnyCodable("ABCD123456.com.test.app")
                ],
                ExpirationDate: expirationDate,
                CreationDate: creationDate,
                DeveloperCertificates: nil,
                ProvisionedDevices: ["device1", "device2"],
                ProvisionsAllDevices: false,
                Platform: ["iOS"]
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)

            #expect(provisioningInfo.name == "Test Development Profile")
            #expect(provisioningInfo.teamName == "Test Team LLC")
            #expect(provisioningInfo.teamID == "ABCD123456")
            #expect(provisioningInfo.appID == "My Test App")
            #expect(provisioningInfo.expirationDate == expirationDate)
            #expect(provisioningInfo.creationDate == creationDate)
            #expect(provisioningInfo.devices?.count == 2)
            #expect(provisioningInfo.profileType == .development)
            #expect(provisioningInfo.platform == [.iOS])
        }

        @Test("Profile type detection", arguments: [
            (hasDevices: true, getTaskAllow: true, isEnterprise: false, expected: ProvisioningInfo.ProfileType.development),
            (hasDevices: true, getTaskAllow: false, isEnterprise: false, expected: ProvisioningInfo.ProfileType.adHoc),
            (hasDevices: false, getTaskAllow: false, isEnterprise: true, expected: ProvisioningInfo.ProfileType.enterprise),
            (hasDevices: false, getTaskAllow: false, isEnterprise: false, expected: ProvisioningInfo.ProfileType.appStore)
        ])
        func profileTypeDetection(hasDevices: Bool, getTaskAllow: Bool, isEnterprise: Bool, expected: ProvisioningInfo.ProfileType) {
            let mockProfile = RawProfile(
                UUID: "FEDCBA09-8765-4321-FEDC-BA0987654321",
                Name: "Test Profile",
                TeamName: "Test Team",
                TeamIdentifier: ["ABC123"],
                AppIDName: "Test App",
                Entitlements: getTaskAllow ? ["get-task-allow": AnyCodable(true)] : [:],
                ExpirationDate: Date().addingTimeInterval(86400),
                CreationDate: Date(),
                DeveloperCertificates: nil,
                ProvisionedDevices: hasDevices ? ["device1"] : nil,
                ProvisionsAllDevices: isEnterprise,
                Platform: ["iOS"]
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)
            #expect(provisioningInfo.profileType == expected)
        }

        @Test("Platform detection", arguments: [
            (platformStrings: ["iOS"], expected: [ProvisioningInfo.Platform.iOS]),
            (platformStrings: ["macOS"], expected: [ProvisioningInfo.Platform.macOS]),
            (platformStrings: ["OSX"], expected: [ProvisioningInfo.Platform.iOS]),
            (platformStrings: ["tvOS"], expected: [ProvisioningInfo.Platform.tvOS]),
            (platformStrings: ["watchOS"], expected: [ProvisioningInfo.Platform.watchOS]),
            (platformStrings: ["visionOS"], expected: [ProvisioningInfo.Platform.visionOS]),
            (platformStrings: ["iOS", "macOS"], expected: [ProvisioningInfo.Platform.iOS, ProvisioningInfo.Platform.macOS]),
            (platformStrings: ["unknown"], expected: [ProvisioningInfo.Platform.iOS]),
            (platformStrings: nil, expected: [ProvisioningInfo.Platform.iOS])
        ])
        func platformDetection(platformStrings: [String]?, expected: [ProvisioningInfo.Platform]) {
            let mockProfile = RawProfile(
                UUID: "11111111-2222-3333-4444-555555555555",
                Name: "Test Profile",
                TeamName: "Test Team",
                TeamIdentifier: ["ABC123"],
                AppIDName: "Test App",
                Entitlements: [:],
                ExpirationDate: Date().addingTimeInterval(86400),
                CreationDate: Date(),
                DeveloperCertificates: nil,
                ProvisionedDevices: ["device1"],
                ProvisionsAllDevices: false,
                Platform: platformStrings
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)
            #expect(provisioningInfo.platform == expected)
        }

        @Test("Expiration status calculation", arguments: [
            (daysFromNow: -1, expected: ExpirationStatus.expired), // Yesterday
            (daysFromNow: 15, expected: ExpirationStatus.expiring), // 15 days from now
            (daysFromNow: 60, expected: ExpirationStatus.valid) // 60 days from now
        ])
        func expirationStatusCalculation(daysFromNow: Int, expected: ExpirationStatus) {
            let expirationDate = Date().addingTimeInterval(TimeInterval(daysFromNow * 86400))

            let mockProfile = RawProfile(
                UUID: "99999999-8888-7777-6666-555555555555",
                Name: "Test Profile",
                TeamName: "Test Team",
                TeamIdentifier: ["ABC123"],
                AppIDName: "Test App",
                Entitlements: [:],
                ExpirationDate: expirationDate,
                CreationDate: Date(),
                DeveloperCertificates: nil,
                ProvisionedDevices: ["device1"],
                ProvisionsAllDevices: false,
                Platform: ["iOS"]
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)
            #expect(provisioningInfo.expirationStatus == expected)
        }

        @Test("Default values for missing fields")
        func defaultValues() {
            let mockProfile = RawProfile(
                UUID: nil,
                Name: nil,
                TeamName: nil,
                TeamIdentifier: nil,
                AppIDName: nil,
                Entitlements: nil,
                ExpirationDate: nil,
                CreationDate: nil,
                DeveloperCertificates: nil,
                ProvisionedDevices: nil,
                ProvisionsAllDevices: nil,
                Platform: nil
            )

            let provisioningInfo = ProvisioningInfo(from: mockProfile)

            #expect(provisioningInfo.name == "Unknown")
            #expect(provisioningInfo.teamName == "Unknown Team")
            #expect(provisioningInfo.teamID == "Unknown")
            #expect(provisioningInfo.appID == "Unknown App")
            #expect(provisioningInfo.expirationDate == Date.distantFuture)
            #expect(provisioningInfo.creationDate == Date.distantPast)
            #expect(provisioningInfo.devices == nil)
            #expect(provisioningInfo.certificates.isEmpty)
            #expect(provisioningInfo.entitlements.isEmpty)
            #expect(provisioningInfo.platform == [.iOS])
        }
    }

    @Suite("AnyCodable Tests", .tags(.models))
    struct AnyCodableTests {
        @Test("AnyCodable value storage")
        func anyCodableValueStorage() {
            let testCases: [(Any, String)] = [
                ("test string", "String"),
                (true, "Bool"),
                (42, "Int"),
                (3.14, "Double"),
                (["one", "two", "three"], "Array"),
                (["key1": "value1", "key2": "value2"], "Dictionary")
            ]

            for (value, typeName) in testCases {
                let anyCodable = AnyCodable(value)

                switch typeName {
                case "String":
                    #expect(anyCodable.value as? String == value as? String)
                case "Bool":
                    #expect(anyCodable.value as? Bool == value as? Bool)
                case "Int":
                    #expect(anyCodable.value as? Int == value as? Int)
                case "Double":
                    #expect(anyCodable.value as? Double == value as? Double)
                case "Array":
                    #expect(anyCodable.value as? [String] == value as? [String])
                case "Dictionary":
                    #expect(anyCodable.value as? [String: String] == value as? [String: String])
                default:
                    Issue.record("Unexpected type: \(typeName)")
                }
            }
        }

        @Test("AnyCodable complex structures")
        func anyCodableComplexStructures() throws {
            let complexValue: [String: Any] = [
                "string": "value",
                "number": 42,
                "bool": true,
                "array": ["one", "two"],
                "nested": ["key": "value"]
            ]

            let anyCodable = AnyCodable(complexValue)

            // Test encoding/decoding
            let jsonData = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: jsonData)

            // Verify complex structure preservation
            let decodedDict = try #require(decoded.value as? [String: Any])
            #expect(decodedDict["string"] as? String == "value")
            #expect(decodedDict["number"] as? Int == 42)
            #expect(decodedDict["bool"] as? Bool == true)
            #expect(decodedDict["array"] as? [String] == ["one", "two"])
            #expect((decodedDict["nested"] as? [String: String])?["key"] == "value")
        }

        @Test("AnyCodable unsupported type throws error")
        func anyCodableUnsupportedType() throws {
            // Create JSON with null value
            let jsonData = "null".data(using: .utf8)!

            let decoder = JSONDecoder()
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(AnyCodable.self, from: jsonData)
            }
        }
    }

    @Suite("RawProfile Tests", .tags(.models))
    struct RawProfileTests {
        @Test("RawProfile Codable conformance")
        func rawProfileCodable() throws {
            let originalProfile = RawProfile(
                UUID: "12345",
                Name: "Test",
                TeamName: "Team",
                TeamIdentifier: ["ID"],
                AppIDName: "App",
                Entitlements: ["bool": AnyCodable(true), "string": AnyCodable("value")],
                ExpirationDate: Date(),
                CreationDate: Date(),
                DeveloperCertificates: [Data([0x01, 0x02, 0x03])],
                ProvisionedDevices: ["device"],
                ProvisionsAllDevices: true,
                Platform: ["iOS", "macOS"]
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(originalProfile)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedProfile = try decoder.decode(RawProfile.self, from: data)

            #expect(decodedProfile.UUID == originalProfile.UUID)
            #expect(decodedProfile.Name == originalProfile.Name)
            #expect(decodedProfile.TeamName == originalProfile.TeamName)
            #expect(decodedProfile.TeamIdentifier == originalProfile.TeamIdentifier)
            #expect(decodedProfile.AppIDName == originalProfile.AppIDName)
            #expect(decodedProfile.ProvisionedDevices == originalProfile.ProvisionedDevices)
            #expect(decodedProfile.ProvisionsAllDevices == originalProfile.ProvisionsAllDevices)
            #expect(decodedProfile.Platform == originalProfile.Platform)
        }
    }
}
