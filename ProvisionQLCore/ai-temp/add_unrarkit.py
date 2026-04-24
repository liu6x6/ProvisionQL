import re

package_path = "/Users/spxt666/ProvisionQL/ProvisionQLCore/Package.swift"
with open(package_path, "r") as f:
    package_content = f.read()

# 1. Add dependency
package_content = re.sub(
    r'\.package\(url: "https://github.com/tsolomko/SWCompression\.git", from: "4\.8\.0"\),',
    '.package(url: "https://github.com/tsolomko/SWCompression.git", from: "4.8.0"),\n        .package(url: "https://github.com/abbeycode/UnrarKit.git", from: "2.9.0"),',
    package_content
)

# 2. Add target dependency
package_content = re.sub(
    r'"SWCompression",',
    '"SWCompression",\n                "UnrarKit",',
    package_content
)

with open(package_path, "w") as f:
    f.write(package_content)

print("Updated Package.swift with UnrarKit")

# 3. Update ArchiveParser.swift
parser_path = "/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift"
with open(parser_path, "r") as f:
    parser_content = f.read()

# Add import
parser_content = parser_content.replace("import SWCompression", "import SWCompression\nimport UnrarKit")

# Implement parseRar logic
rar_logic = """    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
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

# Find the existing parseRar stub and replace it
import re
parser_content = re.sub(
    r'static func parseRar\(_ url: URL\) throws -> ZipArchiveInfo \{.*?throw ArchiveParserError\.missingRarLibrary\n    \}',
    rar_logic,
    parser_content,
    flags=re.DOTALL
)

with open(parser_path, "w") as f:
    f.write(parser_content)

print("Updated ArchiveParser.swift with UnrarKit implementation")
