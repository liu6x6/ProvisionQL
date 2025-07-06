//
//  FileInfoSection.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import SwiftUI

struct FileInfoSection: View {
    let fileURL: URL

    var fileAttributes: [FileAttributeKey: Any]? {
        try? FileManager.default.attributesOfItem(atPath: fileURL.path)
    }

    var fileName: String {
        fileURL.lastPathComponent
    }

    var fileSize: String {
        guard let attributes = fileAttributes,
              let size = attributes[.size] as? NSNumber
        else {
            return "Unknown size"
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size.int64Value)
    }

    var modificationDate: String {
        guard let attributes = fileAttributes,
              let date = attributes[.modificationDate] as? Date
        else {
            return "Unknown date"
        }

        return date.formatted(date: .long, time: .standard)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Padding.small) {
            Text(fileName)
                .codeText()

            Text("\(fileSize), Modified \(modificationDate)")
                .codeText(.subheadline)
                .foregroundColor(.secondary)
        }
        .sectionBackground()
    }
}
