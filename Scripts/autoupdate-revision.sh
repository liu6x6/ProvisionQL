#!/bin/sh
# autoupdate-revision.sh

git=`sh /etc/profile; which git`
commits_count=`${git} rev-list HEAD --count`

filepath="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

echo "Updating ${filepath}"
echo "Current version build ${commits_count}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${commits_count}" "${filepath}"
