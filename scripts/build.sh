#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Building MacNewFile Enhanced Fork ==="
echo "Root directory: ${ROOT_DIR}"

SDK="$(xcrun --show-sdk-path)"
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR="${BUILD_DIR}/MacNewFile.app"
APP_CONTENTS="${APP_DIR}/Contents"
APP_MACOS="${APP_CONTENTS}/MacOS"
APP_RESOURCES="${APP_CONTENTS}/Resources"
APP_PLUGINS="${APP_CONTENTS}/PlugIns"

EXT_DIR="${APP_PLUGINS}/MacNewFileFinderExtension.appex"
EXT_CONTENTS="${EXT_DIR}/Contents"
EXT_MACOS="${EXT_CONTENTS}/MacOS"
EXT_RESOURCES="${EXT_CONTENTS}/Resources"

# 1. Clean and recreate directories
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_MACOS}" "${APP_RESOURCES}" "${APP_PLUGINS}"
mkdir -p "${EXT_MACOS}" "${EXT_RESOURCES}"

# 2. Extract base resources (Assets.car, storyboardc) from dist archive if available
TMP_EXTRACT=$(mktemp -d)
if [ -f "${ROOT_DIR}/dist/MacNewFile.zip" ]; then
    echo "Extracting base assets & storyboard..."
    unzip -q "${ROOT_DIR}/dist/MacNewFile.zip" -d "${TMP_EXTRACT}" || true
    
    if [ -d "${TMP_EXTRACT}/MacNewFile.app/Contents/Resources" ]; then
        cp -R "${TMP_EXTRACT}/MacNewFile.app/Contents/Resources/"* "${APP_RESOURCES}/" || true
    fi
    
    if [ -d "${TMP_EXTRACT}/MacNewFile.app/Contents/PlugIns/MacNewFileFinderExtension.appex/Contents/Resources" ]; then
        cp -R "${TMP_EXTRACT}/MacNewFile.app/Contents/PlugIns/MacNewFileFinderExtension.appex/Contents/Resources/"* "${EXT_RESOURCES}/" || true
    fi
fi
rm -rf "${TMP_EXTRACT}"

# 3. Copy extension templates and localizations
echo "Copying extension templates and localizations..."
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.pages" "${EXT_RESOURCES}/"
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.key" "${EXT_RESOURCES}/"
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.numbers" "${EXT_RESOURCES}/"
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.docx" "${EXT_RESOURCES}/"
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.xlsx" "${EXT_RESOURCES}/"
cp "${ROOT_DIR}/MacNewFileFinderExtension/Blank.pptx" "${EXT_RESOURCES}/"
cp -R "${ROOT_DIR}/MacNewFileFinderExtension/en.lproj" "${EXT_RESOURCES}/"
cp -R "${ROOT_DIR}/MacNewFileFinderExtension/it.lproj" "${EXT_RESOURCES}/"

# Copy app localizations
cp -R "${ROOT_DIR}/MacNewFile/en.lproj" "${APP_RESOURCES}/"
cp -R "${ROOT_DIR}/MacNewFile/it.lproj" "${APP_RESOURCES}/"

# Copy Info.plists
cp "${ROOT_DIR}/MacNewFileFinderExtension/Info.plist" "${EXT_CONTENTS}/Info.plist"
cp "${ROOT_DIR}/MacNewFile/Info.plist" "${APP_CONTENTS}/Info.plist"

# 4. Build FinderSync Extension as a Sandboxed MH_EXECUTE Mach-O Binary
echo "Compiling FinderSync extension executable..."
clang -fobjc-arc -mmacosx-version-min=13.0 -isysroot "${SDK}" \
    -framework Cocoa -framework FinderSync \
    -e _NSExtensionMain \
    "${ROOT_DIR}/MacNewFileFinderExtension/FinderSync.m" \
    -o "${EXT_MACOS}/MacNewFileFinderExtension"

# 5. Build Swift sources for Main App
echo "Compiling Swift components (Settings & Quick Editor)..."
SWIFT_TMP_DIR=$(mktemp -d)
swiftc -c -sdk "${SDK}" -target arm64-apple-macos13.0 -parse-as-library \
    -force-single-frontend-invocation \
    "${ROOT_DIR}/MacNewFile/FileItem.swift" \
    "${ROOT_DIR}/MacNewFile/AppSettings.swift" \
    "${ROOT_DIR}/MacNewFile/SettingsManager.swift" \
    "${ROOT_DIR}/MacNewFile/SettingsView.swift" \
    "${ROOT_DIR}/MacNewFile/SettingsWindowController.swift" \
    "${ROOT_DIR}/MacNewFile/LineNumberGutterView.swift" \
    "${ROOT_DIR}/MacNewFile/QuickEditorWindowController.swift" \
    "${ROOT_DIR}/MacNewFile/GlobalHotkeyManager.swift" \
    -module-name MacNewFile \
    -o "${SWIFT_TMP_DIR}/MacNewFile_swift.o"

# 6. Compile Objective-C and Link Main App Binary
echo "Compiling Objective-C and linking MacNewFile binary..."
clang -fobjc-arc -mmacosx-version-min=13.0 -isysroot "${SDK}" \
    -framework Cocoa -framework SwiftUI -framework Carbon -framework ServiceManagement \
    -L/Library/Developer/CommandLineTools/usr/lib/swift/macosx \
    -Wl,-rpath,/Library/Developer/CommandLineTools/usr/lib/swift/macosx \
    -Wl,-rpath,/usr/lib/swift \
    "${ROOT_DIR}/MacNewFile/main.m" \
    "${ROOT_DIR}/MacNewFile/AppDelegate.m" \
    "${ROOT_DIR}/MacNewFile/ViewController.m" \
    "${SWIFT_TMP_DIR}/MacNewFile_swift.o" \
    -o "${APP_MACOS}/MacNewFile"

rm -rf "${SWIFT_TMP_DIR}"

# 7. Code Signing with Sandboxed Entitlements
echo "Code signing extension binary and bundle..."
codesign --force --sign - --entitlements "${ROOT_DIR}/MacNewFileFinderExtension/MacNewFileFinderExtension.entitlements" "${EXT_MACOS}/MacNewFileFinderExtension"
codesign --force --sign - --entitlements "${ROOT_DIR}/MacNewFileFinderExtension/MacNewFileFinderExtension.entitlements" "${EXT_DIR}"
echo "Code signing main application..."
codesign --force --sign - --entitlements "${ROOT_DIR}/MacNewFile/MacNewFile.entitlements" "${APP_DIR}"

# 8. Install to /Applications for system FinderSync discovery
echo "Installing to /Applications/MacNewFile.app..."
rm -rf /Applications/MacNewFile.app
cp -R "${APP_DIR}" /Applications/

# 9. Register with LaunchServices & pluginkit
echo "Registering with LaunchServices and pluginkit..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/MacNewFile.app || true
pluginkit -a /Applications/MacNewFile.app/Contents/PlugIns/MacNewFileFinderExtension.appex || true
pluginkit -e use -i com.louieyin.MacNewFile.MacNewFileFinderExtension || true

# 10. Create distribution zip
echo "Packaging dist/MacNewFile.zip..."
mkdir -p "${ROOT_DIR}/dist"
(cd "${BUILD_DIR}" && zip -rq "${ROOT_DIR}/dist/MacNewFile.zip" "MacNewFile.app")

echo "=== Build & Installation Complete! ==="
echo "Application installed at: /Applications/MacNewFile.app"
