#!/bin/bash
set -Eeuo pipefail

CURRENT_PROJECT_VERSION="$1"  # e.g. 2.75

[[ -z "$(git diff --staged)" ]] || { echo "git has staged changes; will not bump version"; exit 1; }
[[ "${CURRENT_PROJECT_VERSION::1}" != "v" && "${CURRENT_PROJECT_VERSION::1}" != "V" ]] || { echo "using version name without v"; CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:1}"; }

sed -E -i '' "s/([_\s])VERSION = \"?[-0-9A-Za-z.]*\"?;$/\1VERSION = \"$CURRENT_PROJECT_VERSION\";/g" jitouch/Jitouch/Jitouch.xcodeproj/project.pbxproj
sed -E -i '' "s/([_\s])VERSION = \"?[-0-9A-Za-z.]*\"?;$/\1VERSION = \"$CURRENT_PROJECT_VERSION\";/g" prefpane/Jitouch.xcodeproj/project.pbxproj
sed -E -i '' "s/\"Version [-0-9A-Za-z.]*\"/\"Version $CURRENT_PROJECT_VERSION\"/g" prefpane/Base.lproj/JitouchPref.xib

git add jitouch/Jitouch/Jitouch.xcodeproj/project.pbxproj prefpane/Base.lproj/JitouchPref.xib prefpane/Jitouch.xcodeproj/project.pbxproj
git commit -m "Bump version: $CURRENT_PROJECT_VERSION"
git tag -s "v$CURRENT_PROJECT_VERSION" -m "Jitouch v$CURRENT_PROJECT_VERSION"
