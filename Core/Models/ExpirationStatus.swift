//
//  ExpirationStatus.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation

@frozen
public enum ExpirationStatus: String, Sendable {
    case expired = "Expired"
    case expiring = "Expiring Soon"
    case valid = "Valid"
}
