//
//  CertificateInfo.swift
//  Core
//
//  Created by Evgeny Aleksandrov

import Foundation
import Security

public struct CertificateInfo: Sendable, Codable, Hashable {
    public let subject: String
    public let expirationDate: Date?
}

extension CertificateInfo {
    static func from(data: Data) -> CertificateInfo? {
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            return nil
        }

        let subject = SecCertificateCopySubjectSummary(certificate) as String? ?? "Unknown"

        // Try to get expiration date
        var expirationDate: Date?
        var error: Unmanaged<CFError>?
        if let values = SecCertificateCopyValues(
            certificate,
            [kSecOIDInvalidityDate] as CFArray,
            &error
        ) as? [CFString: Any],
            let invalidityDict = values[kSecOIDInvalidityDate] as? [CFString: Any],
            let dateValue = invalidityDict[kSecPropertyKeyValue]
        {
            expirationDate = dateValue as? Date
        }

        return CertificateInfo(
            subject: subject,
            expirationDate: expirationDate
        )
    }
}
