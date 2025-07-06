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
        var size: Int64 = 0

        // Check if the URL is a directory
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue
        {
            // Calculate total size of directory contents
            size = calculateDirectorySize(at: fileURL)
        } else {
            // For regular files, use the file attributes
            if let fileAttributes,
               let fileSize = fileAttributes[.size] as? NSNumber
            {
                size = fileSize.int64Value
            } else {
                return "Unknown size"
            }
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
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

    private func calculateDirectorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0

        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if let isRegularFile = resourceValues.isRegularFile,
                   isRegularFile,
                   let fileSize = resourceValues.fileSize
                {
                    totalSize += Int64(fileSize)
                }
            } catch {
                // Skip files that can't be accessed
                continue
            }
        }

        return totalSize
    }
}
