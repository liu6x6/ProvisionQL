//
//  ZipParser.swift
//  Core
//
//  Created by Gemini

import Foundation
import ZIPFoundation
import OSLog

public enum ZipParser {
    static let logger = Logger(subsystem: "com.ProvisionQLCore", category: "ZipParser")

    public static func parse(_ url: URL) throws -> ZipArchiveInfo {
        let fileData = try Data(contentsOf: url)
        let archive = try Archive(data: fileData, accessMode: .read)
        
        var files: [ZipFileInfo] = []
        var totalUncompressedSize: Int64 = 0
        var totalCompressedSize: Int64 = 0
        
        for entry in archive {
            let isDirectory = entry.type == .directory
            let uncompressed = Int64(entry.uncompressedSize)
            let compressed = Int64(entry.compressedSize)
            
            let fileInfo = ZipFileInfo(
                path: entry.path,
                uncompressedSize: uncompressed,
                compressedSize: compressed,
                isDirectory: isDirectory
            )
            
            files.append(fileInfo)
            
            if !isDirectory {
                totalUncompressedSize += uncompressed
                totalCompressedSize += compressed
            }
        }
        
        // Sort files alphabetically
        files.sort { $0.path < $1.path }
        
        return ZipArchiveInfo(
            name: url.lastPathComponent,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: totalCompressedSize,
            files: files
        )
    }
}
