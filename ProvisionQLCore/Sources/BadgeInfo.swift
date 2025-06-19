//
//  BadgeInfo.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation

public struct BadgeInfo: Sendable {
    public let deviceCount: Int
    public let expirationStatus: ExpirationStatus
    public let profileType: ProvisioningInfo.ProfileType

    public init(deviceCount: Int, expirationStatus: ExpirationStatus, profileType: ProvisioningInfo.ProfileType) {
        self.deviceCount = deviceCount
        self.expirationStatus = expirationStatus
        self.profileType = profileType
    }

    public init(from provisioningInfo: ProvisioningInfo) {
        deviceCount = provisioningInfo.devices?.count ?? 0
        expirationStatus = provisioningInfo.expirationStatus
        profileType = provisioningInfo.profileType
    }
}
