//
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
        case "zip", "jar", "war":
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
        case "rar":
            return try parseRar(url)
        default:
            throw ArchiveParserError.unsupportedFormat
        }
    }
}

private extension ArchiveParser {
    static func decodePath(entry: Entry) -> String {
        let utf8Path = entry.path(using: .utf8)
        if !utf8Path.isEmpty {
            return utf8Path
        }
        
        let gbkEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        let gbkPath = entry.path(using: gbkEncoding)
        if !gbkPath.isEmpty {
            return gbkPath
        }
        
        return entry.path
    }

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
                path: decodePath(entry: entry),
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
            let isDirectory = entry.type == .directory
            let size = Int64(entry.size ?? 0)
            
            let fileInfo = ZipFileInfo(
                path: entry.name,
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
            let isDirectory = entry.name.hasSuffix("/")
            let size = Int64(entry.size ?? 0)
            
            let fileInfo = ZipFileInfo(
                path: entry.name,
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

                    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
        // FIXME: URKArchive is not available in the current isolated build context.
        // Uncomment when UnrarKit is successfully resolved and imported.
        // let archive = try URKArchive(url: url)
        // let fileInfos = try archive.listFileInfo()
        // 
        // var files: [ZipFileInfo] = []
        // var totalUncompressedSize: Int64 = 0
        // 
        // for info in fileInfos {
        //     let fileInfo = ZipFileInfo(
        //         path: info.name,
        //         uncompressedSize: Int64(info.uncompressedSize),
        //         compressedSize: 0, 
        //         isDirectory: info.isDirectory
        //     )
        //     files.append(fileInfo)
        //     if !info.isDirectory {
        //         totalUncompressedSize += Int64(info.uncompressedSize)
        //     }
        // }
        // 
        // return ZipArchiveInfo(
        //     name: url.lastPathComponent,
        //     fileCount: files.filter { !bash.isDirectory }.count,
        //     totalUncompressedSize: totalUncompressedSize,
        //     totalCompressedSize: 0,
        //     files: files
        // )
        throw ArchiveParserError.missingRarLibrary
    }
}

public enum ArchiveParserError: Error {
    case unsupportedFormat
    case missingRarLibrary
}
