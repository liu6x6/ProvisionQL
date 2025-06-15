//
//  CoreTests.swift
//  CoreTests
//
//  Created by Evgeny Aleksandrov

@testable import Core
import Foundation
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
        @Test("AnyCodable string storage")
        func anyCodableStringStorage() {
            let value = "test string"
            let anyCodable = AnyCodable(value)
            #expect(anyCodable.value as? String == value)
        }

        @Test("AnyCodable bool storage")
        func anyCodableBoolStorage() {
            let value = true
            let anyCodable = AnyCodable(value)
            #expect(anyCodable.value as? Bool == value)
        }

        @Test("AnyCodable int storage")
        func anyCodableIntStorage() {
            let value = 42
            let anyCodable = AnyCodable(value)
            #expect(anyCodable.value as? Int == value)
        }

        @Test("AnyCodable double storage")
        func anyCodableDoubleStorage() {
            let value = 3.14
            let anyCodable = AnyCodable(value)
            #expect(anyCodable.value as? Double == value)
        }

        @Test("AnyCodable array storage")
        func anyCodableArrayStorage() {
            let array = ["one", "two", "three"]
            let anyCodable = AnyCodable(array)

            if let storedArray = anyCodable.value as? [String] {
                #expect(storedArray == array)
            } else {
                Issue.record("Failed to store array in AnyCodable")
            }
        }

        @Test("AnyCodable dictionary storage")
        func anyCodableDictionaryStorage() {
            let dict = ["key1": "value1", "key2": "value2"]
            let anyCodable = AnyCodable(dict)

            if let storedDict = anyCodable.value as? [String: String] {
                #expect(storedDict == dict)
            } else {
                Issue.record("Failed to store dictionary in AnyCodable")
            }
        }
    }
}
