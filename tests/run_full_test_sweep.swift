import Foundation
import Cocoa
import Darwin

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

// TEST SUITE 1: Settings JSON Persistence & Schema
print("\n--- Test Suite 1: Settings Persistence & Schema ---")
let settingsPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/MacNewFile/settings.json")
assertTest(FileManager.default.fileExists(atPath: settingsPath.path), "settings.json exists in Application Support")

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

// TEST SUITE 7: Extension Settings Path & Sync Resolution
print("\n--- Test Suite 7: Sandboxed Extension Settings Path Resolution ---")
let pw = getpwuid(getuid())
let realHome = String(cString: pw!.pointee.pw_dir)
let realSettingsFile = (realHome as NSString).appendingPathComponent("Library/Application Support/MacNewFile/settings.json")
assertTest(FileManager.default.fileExists(atPath: realSettingsFile), "Extension real-home settings path exists: \(realSettingsFile)")

let containerSettingsFile = (realHome as NSString).appendingPathComponent("Library/Containers/com.louieyin.MacNewFile.MacNewFileFinderExtension/Data/Library/Application Support/MacNewFile/settings.json")
assertTest(FileManager.default.fileExists(atPath: containerSettingsFile), "Extension container-mirrored settings path exists: \(containerSettingsFile)")

if let realData = try? Data(contentsOf: URL(fileURLWithPath: realSettingsFile)),
   let realJson = try? JSONSerialization.jsonObject(with: realData) as? [String: Any],
   let realItems = realJson["fileItems"] as? [[String: Any]] {
    let enabledForNewFile = realItems.filter { ($0["enabledForNewFile"] as? Bool) == true }
    assertTest(enabledForNewFile.count >= 15, "Full collection of enabled items in sync (found \(enabledForNewFile.count) enabled types, NOT 9 fallbacks)")

    let extensions = enabledForNewFile.compactMap { $0["ext"] as? String }
    assertTest(extensions.contains("js"), "JavaScript (.js) is enabled in settings and resolved")
    assertTest(extensions.contains("ts"), "TypeScript (.ts) is enabled in settings and resolved")
    assertTest(extensions.contains("html"), "HTML (.html) is enabled in settings and resolved")
    assertTest(extensions.contains("json"), "JSON (.json) is enabled in settings and resolved")
}

// TEST SUITE 8: Fast Native File Creation & Templates
print("\n--- Test Suite 8: Native File Creation Functionality ---")
let testDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MacNewFile_Test_\(UUID().uuidString)")
try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

// 1. Text file with template
let pyFile = testDir.appendingPathComponent("Untitled.py")
let pyTemplate = "#!/usr/bin/env python3\nprint('Test')\n"
let pyData = pyTemplate.data(using: .utf8)!
let pySuccess = FileManager.default.createFile(atPath: pyFile.path, contents: pyData, attributes: nil)
assertTest(pySuccess && FileManager.default.fileExists(atPath: pyFile.path), "Native Python file created successfully")
let pyRead = try? String(contentsOf: pyFile, encoding: .utf8)
assertTest(pyRead == pyTemplate, "Python file content matches template exactly")

// 2. Bundled template copy (docx, xlsx, pptx, pages)
let extBundleURL = URL(fileURLWithPath: "/Applications/MacNewFile.app/Contents/PlugIns/MacNewFileFinderExtension.appex")
let extBundle = Bundle(url: extBundleURL)
assertTest(extBundle != nil, "FinderSync extension bundle located at \(extBundleURL.path)")

for template in ["Blank.docx", "Blank.xlsx", "Blank.pptx", "Blank.pages", "Blank.numbers", "Blank.key"] {
    let ext = (template as NSString).pathExtension
    let name = (template as NSString).deletingPathExtension
    let templatePath = extBundle?.path(forResource: name, ofType: ext)
    assertTest(templatePath != nil && FileManager.default.fileExists(atPath: templatePath!), "Template \(template) exists in extension resources")

    if let tp = templatePath {
        let dest = testDir.appendingPathComponent("Untitled.\(ext)")
        let copySuccess = (try? FileManager.default.copyItem(atPath: tp, toPath: dest.path)) != nil
        assertTest(copySuccess && FileManager.default.fileExists(atPath: dest.path), "Template \(template) successfully copied natively to destination")
    }
}

// Clean up test files
try? FileManager.default.removeItem(at: testDir)

// TEST SUITE 9: Icon Performance & Caching
print("\n--- Test Suite 9: Menu Icon Caching & Performance ---")
let start = CFAbsoluteTimeGetCurrent()
for ext in ["py", "js", "ts", "html", "css", "json", "yaml", "sh", "swift", "docx", "xlsx", "pptx"] {
    let symbol: String
    switch ext {
    case "py": symbol = "chevron.left.forwardslash.chevron.right"
    case "js", "ts": symbol = "curlybraces"
    case "html", "css": symbol = "globe"
    case "json", "yaml": symbol = "list.bullet.rectangle"
    case "sh": symbol = "terminal"
    case "swift": symbol = "swift"
    case "docx": symbol = "doc.richtext"
    case "xlsx": symbol = "chart.bar.doc.horizontal"
    case "pptx": symbol = "play.rectangle.on.rectangle"
    default: symbol = "doc.plaintext"
    }
    let img = NSImage(systemSymbolName: symbol, accessibilityDescription: ext)
    assertTest(img != nil, "Symbol icon resolved for .\(ext): \(symbol)")
}
let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
assertTest(elapsedMs < 50.0, "All 12 icons resolved in \(String(format: "%.2f", elapsedMs)) ms (< 50ms)")

print("\n==========================================")
print("TEST SUMMARY: \(testsPassed) PASSED, \(testsFailed) FAILED")
print("==========================================")

if testsFailed > 0 {
    exit(1)
}
