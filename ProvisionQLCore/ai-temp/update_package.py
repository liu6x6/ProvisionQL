import sys
import re

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Package.swift", "r") as f:
    content = f.read()

# Add SWCompression dependency
dep_str = """.package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/tsolomko/SWCompression.git", from: "4.8.0"),"""
content = re.sub(r'\.package\(url: "https://github.com/weichsel/ZIPFoundation\.git", from: "0\.9\.19"\),', dep_str, content)

# Add SWCompression target
target_str = """"ZIPFoundation",
                "SwiftAXML",
                "SWCompression","""
content = re.sub(r'"ZIPFoundation",\s*"SwiftAXML",', target_str, content)

with open("/Users/spxt666/ProvisionQL/ProvisionQLCore/Package.swift", "w") as f:
    f.write(content)

print("Updated Package.swift")
