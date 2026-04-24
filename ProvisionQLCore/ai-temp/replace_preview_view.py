import sys
import re

with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "r") as f:
    content = f.read()

# Replace ZipParser.parse with ArchiveParser.parse
content = content.replace("ZipParser.parse(url)", "ArchiveParser.parse(url)")

# Replace UTI check
old_uti = 'if contentType.identifier == "public.zip-archive" {'
new_uti = """if contentType.identifier == "public.zip-archive" ||
                contentType.identifier == "org.7-zip.7-zip-archive" ||
                contentType.identifier == "org.gnu.gnu-zip-archive" ||
                contentType.identifier == "public.tar-archive" ||
                url.pathExtension.lowercased() == "7z" ||
                url.pathExtension.lowercased() == "tar" ||
                url.pathExtension.lowercased() == "gz" ||
                url.pathExtension.lowercased() == "tgz"
            {"""
content = content.replace(old_uti, new_uti)

# Replace Title in ZipArchivePreviewView
content = content.replace('Text("ZIP Archive")', 'Text("Archive")')
content = content.replace('Image(systemName: "doc.zipper")', 'Image(systemName: "doc.zipper")')

with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "w") as f:
    f.write(content)

print("Updated PreviewViewController")
