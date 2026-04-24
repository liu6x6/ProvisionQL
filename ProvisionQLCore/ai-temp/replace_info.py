import sys
import re

with open("/Users/spxt666/ProvisionQL/Preview/Info.plist", "r") as f:
    content = f.read()

old_string = """				<string>public.zip-archive</string>
			</array>"""

new_string = """				<string>public.zip-archive</string>
				<string>org.7-zip.7-zip-archive</string>
				<string>org.gnu.gnu-zip-archive</string>
				<string>public.tar-archive</string>
			</array>"""

if old_string in content:
    content = content.replace(old_string, new_string)
    with open("/Users/spxt666/ProvisionQL/Preview/Info.plist", "w") as f:
        f.write(content)
    print("Updated Info.plist.")
else:
    print("Could not find insertion point.")
