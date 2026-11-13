import Cocoa
import SwiftUI

@objc(QuickEditorWindowController)
public class QuickEditorWindowController: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    @objc(sharedController)
    public static let shared = QuickEditorWindowController()

    private var currentFileURL: URL?
    private var isModified: Bool = false {
        didSet {
            updateStatusUI()
        }
    }

    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var gutterView: LineNumberGutterView?
    private var titleLabel: NSTextField!
    private var pathLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var saveButton: NSButton!
    private var iconImageView: NSImageView!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "MacNewFile Quick Editor"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let window = self.window else { return }

        let container = NSView(frame: window.contentView!.bounds)
        container.autoresizingMask = [.width, .height]
        window.contentView = container

        // 1. Top Header Bar (VS Code style titlebar)
        let headerHeight: CGFloat = 46.0
        let headerView = NSVisualEffectView(frame: NSRect(x: 0, y: container.bounds.height - headerHeight, width: container.bounds.width, height: headerHeight))
        headerView.autoresizingMask = [.width, .minYMargin]
        headerView.material = .headerView
        headerView.blendingMode = .withinWindow
        headerView.state = .active
        container.addSubview(headerView)

        // Header Border
        let headerBorder = NSBox(frame: NSRect(x: 0, y: 0, width: headerView.bounds.width, height: 1))
        headerBorder.boxType = .separator
        headerBorder.autoresizingMask = [.width, .maxYMargin]
        headerView.addSubview(headerBorder)

        // File icon
        iconImageView = NSImageView(frame: NSRect(x: 16, y: 11, width: 24, height: 24))
        iconImageView.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "File")
        headerView.addSubview(iconImageView)

        // Title and Path
        titleLabel = NSTextField(labelWithString: "Untitled")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.frame = NSRect(x: 48, y: 22, width: 450, height: 18)
        headerView.addSubview(titleLabel)

        pathLabel = NSTextField(labelWithString: "")
        pathLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.frame = NSRect(x: 48, y: 6, width: 450, height: 16)
        headerView.addSubview(pathLabel)

        // "Open in Default App" button
        let openInAppButton = NSButton(title: "Open in App", target: self, action: #selector(openInDefaultApp))
        openInAppButton.bezelStyle = .rounded
        openInAppButton.font = NSFont.systemFont(ofSize: 12)
        openInAppButton.frame = NSRect(x: headerView.bounds.width - 190, y: 10, width: 100, height: 26)
        openInAppButton.autoresizingMask = [.minXMargin, .minYMargin]
        headerView.addSubview(openInAppButton)

        // "Save" button
        saveButton = NSButton(title: "Save (⌘S)", target: self, action: #selector(saveFile))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "s"
        saveButton.keyEquivalentModifierMask = .command
        saveButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        saveButton.frame = NSRect(x: headerView.bounds.width - 86, y: 10, width: 74, height: 26)
        saveButton.autoresizingMask = [.minXMargin, .minYMargin]
        headerView.addSubview(saveButton)

        // 2. Bottom Status Bar (VS Code style footer)
        let footerHeight: CGFloat = 26.0
        let footerView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: container.bounds.width, height: footerHeight))
        footerView.autoresizingMask = [.width, .maxYMargin]
        footerView.material = .headerView
        footerView.blendingMode = .withinWindow
        footerView.state = .active
        container.addSubview(footerView)

        let footerBorder = NSBox(frame: NSRect(x: 0, y: footerHeight - 1, width: footerView.bounds.width, height: 1))
        footerBorder.boxType = .separator
        footerBorder.autoresizingMask = [.width, .minYMargin]
        footerView.addSubview(footerBorder)

        statusLabel = NSTextField(labelWithString: "Ready")
        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 14, y: 5, width: footerView.bounds.width - 28, height: 16)
        statusLabel.autoresizingMask = [.width]
        footerView.addSubview(statusLabel)

        // 3. Middle Editor Text View & Scroll View
        let editorRect = NSRect(x: 0, y: footerHeight, width: container.bounds.width, height: container.bounds.height - headerHeight - footerHeight)
        scrollView = NSScrollView(frame: editorRect)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder

        let contentSize = scrollView.contentSize
        textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSMakeSize(0.0, contentSize.height)
        textView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.delegate = self
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSMakeSize(8, 8)

        applySettingsAppearance()

        scrollView.documentView = textView

        // Setup Line Numbers Gutter
        gutterView = LineNumberGutterView(textView: textView)
        scrollView.verticalRulerView = gutterView
        scrollView.rulersVisible = SettingsManager.shared.settings.showLineNumbers

        container.addSubview(scrollView)
    }

    private func applySettingsAppearance() {
        let settings = SettingsManager.shared.settings
        var fontSize = CGFloat(settings.quickEditorFontSize)
        if fontSize < 10 { fontSize = 13 }

        var font: NSFont
        if settings.quickEditorFontFamily == "Menlo" {
            font = NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else if settings.quickEditorFontFamily == "Courier New" {
            font = NSFont(name: "Courier New", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else {
            font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }

        textView.font = font

        if settings.quickEditorTheme == "dark" {
            textView.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
            textView.textColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            textView.insertionPointColor = NSColor.white
        } else if settings.quickEditorTheme == "light" {
            textView.backgroundColor = NSColor.white
            textView.textColor = NSColor.black
            textView.insertionPointColor = NSColor.black
        } else {
            // System match
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.textColor = NSColor.textColor
            textView.insertionPointColor = NSColor.controlAccentColor
        }

        if settings.wordWrap {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSMakeSize(scrollView.contentSize.width, CGFloat.greatestFiniteMagnitude)
        } else {
            textView.isHorizontallyResizable = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        }

        scrollView.rulersVisible = settings.showLineNumbers
        gutterView?.updateAttributes()
        gutterView?.needsDisplay = true
    }

    // MARK: - Open & Load File
    @objc public func openFile(atPath path: String) {
        let url = URL(fileURLWithPath: path)
        openFile(at: url)
    }

    @objc public func openFile(at url: URL) {
        self.currentFileURL = url
        applySettingsAppearance()

        do {
            let data = try Data(contentsOf: url)
            if let content = String(data: data, encoding: .utf8) {
                textView.string = content
            } else if let content = String(data: data, encoding: .isoLatin1) {
                textView.string = content
            } else {
                textView.string = "// Warning: File appears to be binary or unsupported encoding.\n"
            }
            isModified = false
        } catch {
            NSLog("[MacNewFile] Error reading file: %@", error.localizedDescription)
            textView.string = "// Error reading file: \(error.localizedDescription)"
            isModified = false
        }

        // Update Header UI
        let fileName = url.lastPathComponent
        let dirPath = url.deletingLastPathComponent().path
        titleLabel.stringValue = fileName
        pathLabel.stringValue = dirPath
        window?.title = "\(fileName) — MacNewFile Quick Editor"

        // Set file icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        iconImageView.image = icon

        updateStatusUI()

        // Bring window to front
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        textView.window?.makeFirstResponder(textView)
    }

    // MARK: - Actions
    @objc public func saveFile() {
        guard let url = currentFileURL else { return }

        do {
            let content = textView.string
            try content.write(to: url, atomically: true, encoding: .utf8)
            isModified = false

            // Visual feedback
            let oldTitle = saveButton.title
            saveButton.title = "Saved ✓"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.saveButton.title = oldTitle
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Save File"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    @objc public func openInDefaultApp() {
        guard let url = currentFileURL else { return }
        NSWorkspace.shared.open(url)
    }

    public func textDidChange(_ notification: Notification) {
        isModified = true
        gutterView?.needsDisplay = true
        updateStatusUI()
    }

    private func updateStatusUI() {
        let content = textView.string
        let lineCount = content.isEmpty ? 1 : content.components(separatedBy: "\n").count
        let charCount = content.count
        let ext = currentFileURL?.pathExtension.uppercased() ?? "TXT"
        let dirtyText = isModified ? "● Modified" : "Saved ✓"

        statusLabel.stringValue = "\(dirtyText)  |  \(lineCount) lines, \(charCount) chars  |  UTF-8  |  \(ext)"
        saveButton.isEnabled = isModified
    }

    // MARK: - Window Delegate
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isModified {
            let alert = NSAlert()
            alert.messageText = "Unsaved Changes"
            alert.informativeText = "Do you want to save the changes you made to \"\(currentFileURL?.lastPathComponent ?? "file")\"?"
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                saveFile()
                return true
            } else if response == .alertSecondButtonReturn {
                isModified = false
                return true
            } else {
                return false
            }
        }
        return true
    }
}
