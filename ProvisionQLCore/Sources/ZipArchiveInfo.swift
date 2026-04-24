//
//  ZipArchiveInfo.swift
//  Core
//
//  Created by Gemini

import Foundation

public struct ZipArchiveInfo {
    public let name: String
    public let fileCount: Int
    public let totalUncompressedSize: Int64
    public let totalCompressedSize: Int64
    public let files: [ZipFileInfo]
    
    public init(name: String, fileCount: Int, totalUncompressedSize: Int64, totalCompressedSize: Int64, files: [ZipFileInfo]) {
        self.name = name
        self.fileCount = fileCount
        self.totalUncompressedSize = totalUncompressedSize
        self.totalCompressedSize = totalCompressedSize
        self.files = files
    }
}

public struct ZipFileInfo: Hashable, Identifiable {
    public let id = UUID()
    public let path: String
    public let uncompressedSize: Int64
    public let compressedSize: Int64
    public let isDirectory: Bool
    
    public init(path: String, uncompressedSize: Int64, compressedSize: Int64, isDirectory: Bool) {
        self.path = path
        self.uncompressedSize = uncompressedSize
        self.compressedSize = compressedSize
        self.isDirectory = isDirectory
    }
}
