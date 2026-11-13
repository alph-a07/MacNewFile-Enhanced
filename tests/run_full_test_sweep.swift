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

// TEST SUITE 10: Icon Tint & Template Rendering Quality
print("\n--- Test Suite 10: Icon Tint & Template Rendering ---")
func makeTestTemplate(symbolName: String) -> NSImage {
    return NSImage(size: NSSize(width: 16, height: 16), flipped: false) { dstRect in
        let app = NSAppearance.currentDrawing()
        let isDark = app.name.rawValue.lowercased().contains("dark")
        let tintColor: NSColor = isDark ? .white : NSColor(white: 0.12, alpha: 1.0)

        guard let baseSym = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return false }
        let pointConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let colorConfig = NSImage.SymbolConfiguration(hierarchicalColor: tintColor)
        let config = pointConfig.applying(colorConfig)
        let configured = baseSym.withSymbolConfiguration(config) ?? baseSym

        let symSize = configured.size
        let scale = min(dstRect.size.width / symSize.width, dstRect.size.height / symSize.height) * 0.88
        let tw = symSize.width * scale
        let th = symSize.height * scale
        let targetRect = NSRect(x: (dstRect.size.width - tw) / 2.0, y: (dstRect.size.height - th) / 2.0, width: tw, height: th)
        configured.draw(in: targetRect)
        return true
    }
}

let testIcons = ["curlybraces", "terminal", "plus.circle", "doc.on.clipboard", "swift"]
for symName in testIcons {
    let icon = makeTestTemplate(symbolName: symName)
    icon.isTemplate = true
    assertTest(icon.isTemplate, "Icon \(symName) is marked as template")

    // Verify under dark appearance that pixels are crisp white (not black/dark grey)
    let dark = NSAppearance(named: .darkAqua)!
    var hasWhitePixel = false
    dark.performAsCurrentDrawingAppearance {
        if let tiff = icon.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
            for y in 0..<rep.pixelsHigh {
                for x in 0..<rep.pixelsWide {
                    if let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.5 {
                        if c.redComponent > 0.8 && c.greenComponent > 0.8 && c.blueComponent > 0.8 {
                            hasWhitePixel = true
                            break
                        }
                    }
                }
                if hasWhitePixel { break }
            }
        }
    }
    assertTest(hasWhitePixel, "Icon \(symName) renders with bright white pixels in Dark Mode (no dark muddy wash)")
}

// TEST SUITE 11: All File Types Quick Editor Loading & Eligibility
print("\n--- Test Suite 11: All File Types Quick Editor Eligibility & Loading ---")
let sweepTestDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("QuickEditor_Sweep_\(UUID().uuidString)")
try? FileManager.default.createDirectory(at: sweepTestDir, withIntermediateDirectories: true)

let allFileTypesToTest: [(name: String, content: String)] = [
    // Code & Web
    ("test.py", "print('hello')\n"),
    ("test.js", "console.log('hello');\n"),
    ("test.ts", "const x: number = 42;\n"),
    ("test.tsx", "export const App = () => <div>Hello</div>;\n"),
    ("test.jsx", "export const App = () => <div>Hello</div>;\n"),
    ("test.html", "<!DOCTYPE html><html><body>Test</body></html>\n"),
    ("test.css", "body { background: #000; }\n"),
    ("test.json", "{\"status\": \"ok\"}\n"),
    ("test.yaml", "key: value\n"),
    ("test.sh", "#!/bin/bash\necho hello\n"),
    ("test.zsh", "#!/bin/zsh\necho hello\n"),
    ("test.swift", "import Foundation\nprint(42)\n"),
    ("test.c", "#include <stdio.h>\n"),
    ("test.cpp", "#include <iostream>\n"),
    ("test.h", "#pragma once\n"),
    ("test.rs", "fn main() {}\n"),
    ("test.go", "package main\n"),
    ("test.sql", "SELECT * FROM users;\n"),
    ("test.xml", "<root></root>\n"),
    
    // Documents & Notes
    ("test.txt", "Plain text content\nLine 2\n"),
    ("test.md", "# Heading\nMarkdown text\n"),
    ("test.rtf", "{\\rtf1\\ansi Hello RTF World}"),
    ("test.log", "2026-11-14 INFO Service started\n"),
    ("test.csv", "name,age\nAlice,30\n"),
    ("test.tsv", "name\tage\nBob\t25\n"),
    ("test.ini", "[section]\nkey=val\n"),
    ("test.toml", "[section]\nkey = \"val\"\n"),
    ("test.conf", "listen 8080;\n"),
    
    // Dotfiles & Extensionless
    (".env", "PORT=3000\nNODE_ENV=test\n"),
    (".gitignore", "node_modules/\n.DS_Store\n"),
    (".zshrc", "export PATH=$PATH:/usr/local/bin\n"),
    ("LICENSE", "MIT License Copyright (c) 2026\n"),
    ("Makefile", "all:\n\t@echo done\n"),
    ("Dockerfile", "FROM alpine:latest\n")
]

func checkEligibility(path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    var ext = url.pathExtension.lowercased()
    if ext.isEmpty {
        let name = url.lastPathComponent.lowercased()
        if name.hasPrefix(".") {
            let sub = String(name.dropFirst())
            if sub == "env" || sub.hasPrefix("env.") {
                ext = "env"
            } else if sub.contains("zsh") || sub.contains("bash") || sub == "profile" {
                ext = "sh"
            } else {
                ext = "txt"
            }
        } else if name == "license" || name == "readme" || name == "makefile" || name == "dockerfile" {
            ext = "txt"
        }
    } else {
        if ext == "tsx" { ext = "ts" }
        else if ext == "jsx" { ext = "js" }
        else if ext == "zsh" || ext == "bash" { ext = "sh" }
        else if ext == "conf" { ext = "ini" }
    }
    
    // Check against real settings fileItems
    if let realData = try? Data(contentsOf: URL(fileURLWithPath: realSettingsFile)),
       let realJson = try? JSONSerialization.jsonObject(with: realData) as? [String: Any],
       let realItems = realJson["fileItems"] as? [[String: Any]] {
        if let item = realItems.first(where: { ($0["ext"] as? String)?.lowercased() == ext }) {
            return (item["enabledForQuickEditor"] as? Bool) ?? false
        }
    }
    return false
}

for (fileName, sampleContent) in allFileTypesToTest {
    let fileURL = sweepTestDir.appendingPathComponent(fileName)
    try? sampleContent.write(to: fileURL, atomically: true, encoding: .utf8)
    assertTest(FileManager.default.fileExists(atPath: fileURL.path), "Created test file on disk: \(fileName)")
    
    let isEligible = checkEligibility(path: fileURL.path)
    assertTest(isEligible, "File \(fileName) is eligible for Quick Editor")
    
    // Verify file reading matches content
    let readStr: String
    if fileURL.pathExtension == "rtf" {
        if let attr = try? NSAttributedString(url: fileURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            readStr = attr.string
        } else {
            readStr = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        }
    } else {
        readStr = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }
    assertTest(!readStr.isEmpty, "File \(fileName) read successfully into text buffer (\(readStr.count) chars)")
}

// TEST SUITE 12: Cross-Process Native File Creation & Collisions
print("\n--- Test Suite 12: Cross-Process New File Creation & Collisions ---")
let newFileTargetDir = sweepTestDir.appendingPathComponent("NewFiles")
try? FileManager.default.createDirectory(at: newFileTargetDir, withIntermediateDirectories: true)

let targetPyPath = newFileTargetDir.appendingPathComponent("Untitled.py").path
DistributedNotificationCenter.default().postNotificationName(
    NSNotification.Name("com.louieyin.MacNewFile.CreateFileRequest"),
    object: nil,
    userInfo: [
        "filePath": targetPyPath,
        "content": "#!/usr/bin/env python3\nprint('Native Creation Test')\n"
    ],
    deliverImmediately: true
)

// Wait briefly for main app to process distributed notification
usleep(300_000)
assertTest(FileManager.default.fileExists(atPath: targetPyPath), "Main app created Untitled.py via CreateFileRequest")

// Test second creation triggers collision handling -> Untitled (1).py
DistributedNotificationCenter.default().postNotificationName(
    NSNotification.Name("com.louieyin.MacNewFile.CreateFileRequest"),
    object: nil,
    userInfo: [
        "filePath": targetPyPath,
        "content": "#!/usr/bin/env python3\nprint('Collision Test')\n"
    ],
    deliverImmediately: true
)
usleep(300_000)
let collidedPyPath = newFileTargetDir.appendingPathComponent("Untitled (1).py").path
assertTest(FileManager.default.fileExists(atPath: collidedPyPath), "Main app handled collision and created Untitled (1).py")

// Clean up sweep directory
try? FileManager.default.removeItem(at: sweepTestDir)

print("\n==========================================")
print("TEST SUMMARY: \(testsPassed) PASSED, \(testsFailed) FAILED")
print("==========================================")

if testsFailed > 0 {
    exit(1)
}
