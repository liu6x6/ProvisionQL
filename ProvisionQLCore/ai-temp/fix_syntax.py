import sys

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "r") as f:
    content = f.read()

# Fix the placement of `parseRar` inside `private extension ArchiveParser`
old_content = """        )
    }
}


    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {"""

new_content = """        )
    }

    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {"""

content = content.replace(old_content, new_content)

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "w") as f:
    f.write(content)

print("Fixed syntax error in ArchiveParser.swift")
