import sys
import re

package_path = "/Users/spxt666/ProvisionQL/ProvisionQLCore/Package.swift"
with open(package_path, "r") as f:
    content = f.read()

# Fix the path to UnrarKit exclude in UnrarKit target
content = content.replace("                \"unrar/rar.cpp\"\n", "                \"unrar/rar.cpp\",\n                \"unrar/blake2s_ref.cpp\"\n")

with open(package_path, "w") as f:
    f.write(content)
