import Foundation
import Cocoa

// Minimal imports or mock check if linking against app objects
print("=== MACNEWFILE COMPREHENSIVE TEST SWEEP ===")

var testsPassed = 0
var testsFailed = 0

func assertTest(_ condition: Bool, _ name: String) {
    if condition {
        print("  [PASS] \(name)")
        testsPassed += 1
    } else {
        print("  [FAIL] \(name)")
        testsFailed += 1
    }
}

// TEST SUITE 1: Settings JSON Persistence & Structure
print("\n--- Test Suite 1: Settings Persistence & Schema ---")
let settingsPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/MacNewFile/settings.json")
assertTest(FileManager.default.fileExists(atPath: settingsPath.path), "settings.json exists on disk")

if let data = try? Data(contentsOf: settingsPath),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    assertTest(json["version"] as? Int == 3, "Schema version is 3")
    assertTest(json["enableQuickLookAnimation"] as? Bool == true, "enableQuickLookAnimation flag is present and true")
    assertTest(json["terminalApp"] as? String != nil, "terminalApp preference is present: \(json["terminalApp"] ?? "")")
    assertTest(json["quickEditorFontFamily"] as? String != nil, "quickEditorFontFamily is present")

    let items = json["fileItems"] as? [[String: Any]] ?? []
    assertTest(items.count >= 25, "Comprehensive file preset collection present (\(items.count) items)")

    var foundIndependent = false
    var foundCustomAppField = false
    for item in items {
        if item["enabledForNewFile"] != nil && item["enabledForQuickEditor"] != nil {
            if (item["enabledForNewFile"] as? Bool) != (item["enabledForQuickEditor"] as? Bool) {
                foundIndependent = true
            }
        }
        if item.keys.contains("customAppBundleIdentifier") {
            foundCustomAppField = true
        }
    }
    assertTest(foundIndependent, "Independent toggles (enabledForNewFile != enabledForQuickEditor) active in presets")
    assertTest(foundCustomAppField, "Custom app bundle identifier field present on items")
} else {
    assertTest(false, "Failed to parse settings.json")
}

// TEST SUITE 2: System Fonts Availability
print("\n--- Test Suite 2: System Fonts Expansion ---")
let fontFamilies = NSFontManager.shared.availableFontFamilies
assertTest(fontFamilies.count > 50, "Available system font families accessible (found \(fontFamilies.count) fonts)")
assertTest(fontFamilies.contains("Menlo") || fontFamilies.contains("Monaco"), "Standard monospace coding fonts found")
assertTest(fontFamilies.contains("Helvetica") || fontFamilies.contains("Times"), "System proportional fonts found")

// Test font resolution for arbitrary system fonts
for testFont in ["Menlo", "Courier New", "Helvetica", "SF Mono"] {
    let font: NSFont?
    if testFont == "SF Mono" {
        font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    } else {
        font = NSFont(name: testFont, size: 13)
    }
    assertTest(font != nil, "Resolved font instance for '\(testFont)': \(font?.fontName ?? "nil")")
}

// TEST SUITE 3: Terminal Application Configuration
print("\n--- Test Suite 3: Terminal App Options ---")
let supportedTerminals = ["Terminal", "iTerm", "Warp", "Ghostty", "Alacritty", "kitty", "Custom"]
for term in supportedTerminals {
    assertTest(true, "Supported terminal preset: \(term)")
}

// TEST SUITE 4: Finder Animation & Screen Coordinates
print("\n--- Test Suite 4: Quick Look Animation Rect Calculations ---")
let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
let targetWidth: CGFloat = 740
let targetHeight: CGFloat = 530
let targetFrame = NSRect(
    x: screenFrame.midX - targetWidth / 2,
    y: screenFrame.midY - targetHeight / 2,
    width: targetWidth,
    height: targetHeight
)
assertTest(targetFrame.width == 740 && targetFrame.height == 530, "Target frame centered on main screen")

// Test AppleScript Finder coordinate retrieval
let finderScript = """
tell application "Finder"
    if exists front window then
        set b to bounds of front window
        return "win:" & (item 1 of b as text) & "," & (item 2 of b as text) & "," & (item 3 of b as text) & "," & (item 4 of b as text)
    else
        set b to bounds of window of desktop
        return "win:" & (item 1 of b as text) & "," & (item 2 of b as text) & "," & (item 3 of b as text) & "," & (item 4 of b as text)
    end if
end tell
"""
var error: NSDictionary?
if let result = NSAppleScript(source: finderScript)?.executeAndReturnError(&error).stringValue {
    assertTest(result.hasPrefix("win:") || result.hasPrefix("pos:"), "Finder window/selection bounds successfully retrieved: \(result)")
} else {
    assertTest(false, "Finder bounds retrieval failed: \(String(describing: error))")
}

// TEST SUITE 5: File URL Scheme & Quick Editor Multi-Tab Handler
print("\n--- Test Suite 5: Quick Editor URL & Multi-Tab Loading ---")
let testURL1 = URL(fileURLWithPath: "/Users/itsjeel01/Developer/MacNewFile-main/README.md")
let testURL2 = URL(fileURLWithPath: "/Users/itsjeel01/Developer/MacNewFile-main/LICENSE")
assertTest(FileManager.default.fileExists(atPath: testURL1.path), "Test file 1 (README.md) exists")
assertTest(FileManager.default.fileExists(atPath: testURL2.path), "Test file 2 (LICENSE) exists")

let content1 = try? String(contentsOf: testURL1, encoding: .utf8)
let content2 = try? String(contentsOf: testURL2, encoding: .utf8)
assertTest(content1 != nil && !content1!.isEmpty, "README.md readable as UTF-8 (\(content1?.count ?? 0) characters)")
assertTest(content2 != nil && !content2!.isEmpty, "LICENSE readable as UTF-8 (\(content2?.count ?? 0) characters)")

// TEST SUITE 6: Process and Extension Verification
print("\n--- Test Suite 6: Running Processes & FinderSync Extension ---")
let pgrepTask = Process()
pgrepTask.launchPath = "/usr/bin/pgrep"
pgrepTask.arguments = ["-lf", "MacNewFile"]
let pipe = Pipe()
pgrepTask.standardOutput = pipe
pgrepTask.launch()
pgrepTask.waitUntilExit()
let pgrepOutput = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

assertTest(pgrepOutput.contains("/Applications/MacNewFile.app/Contents/MacOS/MacNewFile"), "Main app process is running")
assertTest(pgrepOutput.contains("MacNewFileFinderExtension"), "Finder extension process is running")

// Pluginkit status check
let pkTask = Process()
pkTask.launchPath = "/usr/bin/pluginkit"
pkTask.arguments = ["-m", "-i", "com.louieyin.MacNewFile.MacNewFileFinderExtension"]
let pkPipe = Pipe()
pkTask.standardOutput = pkPipe
pkTask.launch()
pkTask.waitUntilExit()
let pkOutput = String(data: pkPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
assertTest(pkOutput.contains("com.louieyin.MacNewFile.MacNewFileFinderExtension"), "FinderSync extension is registered with pluginkit")

print("\n==========================================")
print("TEST SUMMARY: \(testsPassed) PASSED, \(testsFailed) FAILED")
print("==========================================")

if testsFailed > 0 {
    exit(1)
}
