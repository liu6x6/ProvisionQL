# coding=utf-8
content = """//
//  ArchiveParser.swift
//  Core
//
//  Created by Gemini

import Foundation
import ZIPFoundation
import SWCompression

public enum ArchiveParser {
    public static func parse(_ url: URL) throws -> ZipArchiveInfo {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "zip":
            return try parseZip(url)
        case "gz", "tgz":
            if url.path.lowercased().hasSuffix(".tar.gz") || fileExtension == "tgz" {
                return try parseTarGz(url)
            }
            throw ArchiveParserError.unsupportedFormat
        case "tar":
            return try parseTar(url)
        case "7z":
            return try parse7z(url)
        default:
            throw ArchiveParserError.unsupportedFormat
        }
    }
}

private extension ArchiveParser {
    static func parseZip(_ url: URL) throws -> ZipArchiveInfo {
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
        
        return ZipArchiveInfo(
            name: url.lastPathComponent,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: totalCompressedSize,
            files: files
        )
    }

    static func parseTar(_ url: URL) throws -> ZipArchiveInfo {
        let fileData = try Data(contentsOf: url)
        return try parseTarData(fileData, fileName: url.lastPathComponent, compressedSize: Int64(fileData.count))
    }
    
    static func parseTarGz(_ url: URL) throws -> ZipArchiveInfo {
        let fileData = try Data(contentsOf: url)
        let decompressedData = try GzipArchive.unarchive(archive: fileData)
        return try parseTarData(decompressedData, fileName: url.lastPathComponent, compressedSize: Int64(fileData.count))
    }
    
    static func parseTarData(_ data: Data, fileName: String, compressedSize: Int64) throws -> ZipArchiveInfo {
        let tarEntries = try TarContainer.info(container: data)
        
        var files: [ZipFileInfo] = []
        var totalUncompressedSize: Int64 = 0
        
        for entry in tarEntries {
            let isDirectory = entry.info.type == .directory
            let size = Int64(entry.info.size ?? 0)
            
            let fileInfo = ZipFileInfo(
                path: entry.info.name,
                uncompressedSize: size,
                compressedSize: size,
                isDirectory: isDirectory
            )
            
            files.append(fileInfo)
            
            if !isDirectory {
                totalUncompressedSize += size
            }
        }
        
        return ZipArchiveInfo(
            name: fileName,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: compressedSize,
            files: files
        )
    }
    
    static func parse7z(_ url: URL) throws -> ZipArchiveInfo {
        let fileData = try Data(contentsOf: url)
        let entries = try SevenZipContainer.info(container: fileData)
        
        var files: [ZipFileInfo] = []
        var totalUncompressedSize: Int64 = 0
        
        for entry in entries {
            let isDirectory = entry.info.isDirectory
            let size = Int64(entry.info.size ?? 0)
            
            let fileInfo = ZipFileInfo(
                path: entry.info.name,
                uncompressedSize: size,
                compressedSize: 0,
                isDirectory: isDirectory
            )
            
            files.append(fileInfo)
            
            if !isDirectory {
                totalUncompressedSize += size
            }
        }
        
        return ZipArchiveInfo(
            name: url.lastPathComponent,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: Int64(fileData.count),
            files: files
        )
    }
}

public enum ArchiveParserError: Error {
    case unsupportedFormat
}
"""
with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "w") as f:
    f.write(content)
