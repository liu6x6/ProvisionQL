import sys

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "r") as f:
    content = f.read()

# Fix TarEntryInfo and SevenZipEntryInfo access
new_content = content.replace("entry.info.type == .directory", "entry.type == .directory")
new_content = new_content.replace("entry.info.size", "entry.size")
new_content = new_content.replace("entry.info.name", "entry.name")
new_content = new_content.replace("entry.info.isDirectory", "entry.isDirectory")

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Sources/ArchiveParser.swift", "w") as f:
    f.write(new_content)

print("Fixed property access in ArchiveParser.swift")
