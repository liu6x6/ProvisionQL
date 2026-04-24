import sys

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "r") as f:
    content = f.read()

# Enable URKArchive parsing logic since we now have UnrarKit target in Package.swift
old_logic = """    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
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
        //     fileCount: files.filter { !$0.isDirectory }.count,
        //     totalUncompressedSize: totalUncompressedSize,
        //     totalCompressedSize: 0,
        //     files: files
        // )
        throw ArchiveParserError.missingRarLibrary
    }"""

new_logic = """    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
        let archive = try URKArchive(url: url)
        let fileInfos = try archive.listFileInfo()
        
        var files: [ZipFileInfo] = []
        var totalUncompressedSize: Int64 = 0
        
        for info in fileInfos {
            let fileInfo = ZipFileInfo(
                path: info.name,
                uncompressedSize: Int64(info.uncompressedSize),
                compressedSize: 0, 
                isDirectory: info.isDirectory
            )
            files.append(fileInfo)
            if !info.isDirectory {
                totalUncompressedSize += Int64(info.uncompressedSize)
            }
        }
        
        return ZipArchiveInfo(
            name: url.lastPathComponent,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: 0,
            files: files
        )
    }"""

import re
content = re.sub(r'static func parseRar\(_ url: URL\) throws -> ZipArchiveInfo \{.*?throw ArchiveParserError\.missingRarLibrary\n    \}', new_logic, content, flags=re.DOTALL)
content = content.replace("import SWCompression\n", "import SWCompression\nimport UnrarKit\n")

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "w") as f:
    f.write(content)

print("Enabled UnrarKit parsing.")
