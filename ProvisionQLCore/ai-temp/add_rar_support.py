import sys
import re

# 1. Update PreviewViewController.swift
with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "r") as f:
    vc_content = f.read()

old_uti_check = """contentType.identifier == "public.tar-archive" ||
                url.pathExtension.lowercased() == "7z" ||"""

new_uti_check = """contentType.identifier == "public.tar-archive" ||
                contentType.identifier == "com.rarlab.rar-archive" ||
                url.pathExtension.lowercased() == "rar" ||
                url.pathExtension.lowercased() == "7z" ||"""

if old_uti_check in vc_content:
    vc_content = vc_content.replace(old_uti_check, new_uti_check)
    with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "w") as f:
        f.write(vc_content)
    print("Updated PreviewViewController.swift")
else:
    print("Could not find UTI check in PreviewViewController.swift")

# 2. Update Info.plist
with open("/Users/spxt666/ProvisionQL/Preview/Info.plist", "r") as f:
    plist_content = f.read()

old_plist = """				<string>public.tar-archive</string>
			</array>"""

new_plist = """				<string>public.tar-archive</string>
				<string>com.rarlab.rar-archive</string>
				<string>public.rar</string>
			</array>"""

if old_plist in plist_content:
    plist_content = plist_content.replace(old_plist, new_plist)
    with open("/Users/spxt666/ProvisionQL/Preview/Info.plist", "w") as f:
        f.write(plist_content)
    print("Updated Info.plist")
else:
    print("Could not find array in Info.plist")

# 3. Update ArchiveParser.swift
with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "r") as f:
    parser_content = f.read()

old_parser_switch = """case "7z":
            return try parse7z(url)
        default:"""

new_parser_switch = """case "7z":
            return try parse7z(url)
        case "rar":
            return try parseRar(url)
        default:"""

old_parser_error = """public enum ArchiveParserError: Error {
    case unsupportedFormat
}"""

new_parser_error = """
    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
        // FIXME: 沙盒网络受限，无法拉取 UnrarKit 或 C++ libunrar 源码。
        // 当你在有网络的环境下，请在此处接入 UnrarKit 代码：
        // let archive = try URKArchive(url: url)
        // var files: [ZipFileInfo] = []
        // for name in try archive.listFilenames() {
        //     let isDirectory = name.hasSuffix("/") // 或依据 API 判断
        //     files.append(ZipFileInfo(path: name, uncompressedSize: 0, compressedSize: 0, isDirectory: isDirectory))
        // }
        // return ZipArchiveInfo(name: url.lastPathComponent, fileCount: files.filter { !$0.isDirectory }.count, totalUncompressedSize: 0, totalCompressedSize: 0, files: files)
        
        throw ArchiveParserError.missingRarLibrary
    }
}

public enum ArchiveParserError: Error {
    case unsupportedFormat
    case missingRarLibrary
}"""

if old_parser_switch in parser_content:
    parser_content = parser_content.replace(old_parser_switch, new_parser_switch)
    parser_content = parser_content.replace(old_parser_error, new_parser_error)
    with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "w") as f:
        f.write(parser_content)
    print("Updated ArchiveParser.swift")
else:
    print("Could not find switch in ArchiveParser.swift")

