import Cocoa
import SwiftUI
import UniformTypeIdentifiers

@objc(QuickEditorWindowController)
public class QuickEditorWindowController: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    @objc(sharedController)
    public static let shared = QuickEditorWindowController()

    public private(set) var currentFileURL: URL?
    private var isModified: Bool = false {
        didSet {
            updateStatusUI()
        }
    }

    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var gutterView: LineNumberGutterView?
    private var backgroundVisualEffect: NSVisualEffectView!
    private var titleLabel: NSTextField!
    private var pathLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var saveIndicatorLabel: NSTextField!
    private var iconImageView: NSImageView!
    private var openWithButton: NSPopUpButton!

    private var selectionPollingTimer: Timer?
    private var compatibleApps: [URL] = []

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.center()
        panel.isReleasedWhenClosed = false
        super.init(window: panel)
        panel.delegate = self
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let window = self.window else { return }

        // Root container with dark/vibrant HUD background like Quick Look
        backgroundVisualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        backgroundVisualEffect.autoresizingMask = [.width, .height]
        backgroundVisualEffect.material = .hudWindow
        backgroundVisualEffect.blendingMode = .behindWindow
        backgroundVisualEffect.state = .active
        window.contentView = backgroundVisualEffect

        let container = backgroundVisualEffect!

        // Top Bar (Quick Look style header)
        let headerHeight: CGFloat = 44.0
        let headerView = NSView(frame: NSRect(x: 0, y: container.bounds.height - headerHeight, width: container.bounds.width, height: headerHeight))
        headerView.autoresizingMask = [.width, .minYMargin]
        container.addSubview(headerView)

        // File icon
        iconImageView = NSImageView(frame: NSRect(x: 64, y: 10, width: 22, height: 22))
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        headerView.addSubview(iconImageView)

        // Title and Folder path
        titleLabel = NSTextField(labelWithString: "Untitled")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 92, y: 20, width: 320, height: 18)
        headerView.addSubview(titleLabel)

        pathLabel = NSTextField(labelWithString: "")
        pathLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.frame = NSRect(x: 92, y: 6, width: 320, height: 15)
        headerView.addSubview(pathLabel)

        // Save Status Indicator
        saveIndicatorLabel = NSTextField(labelWithString: "")
        saveIndicatorLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        saveIndicatorLabel.textColor = .secondaryLabelColor
        saveIndicatorLabel.alignment = .right
        saveIndicatorLabel.frame = NSRect(x: headerView.bounds.width - 330, y: 14, width: 100, height: 16)
        saveIndicatorLabel.autoresizingMask = [.minXMargin, .minYMargin]
        headerView.addSubview(saveIndicatorLabel)

        // "Open with..." PopUp Menu Button (Quick Look style)
        openWithButton = NSPopUpButton(frame: NSRect(x: headerView.bounds.width - 215, y: 8, width: 200, height: 26), pullsDown: false)
        openWithButton.bezelStyle = .rounded
        openWithButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        openWithButton.autoresizingMask = [.minXMargin, .minYMargin]
        openWithButton.target = self
        openWithButton.action = #selector(handleOpenWithSelection(_:))
        headerView.addSubview(openWithButton)

        // Header bottom separator line
        let headerBorder = NSBox(frame: NSRect(x: 0, y: 0, width: headerView.bounds.width, height: 1))
        headerBorder.boxType = .separator
        headerBorder.autoresizingMask = [.width, .maxYMargin]
        headerView.addSubview(headerBorder)

        // Bottom Status Bar
        let footerHeight: CGFloat = 24.0
        let footerView = NSView(frame: NSRect(x: 0, y: 0, width: container.bounds.width, height: footerHeight))
        footerView.autoresizingMask = [.width, .maxYMargin]
        container.addSubview(footerView)

        let footerBorder = NSBox(frame: NSRect(x: 0, y: footerHeight - 1, width: footerView.bounds.width, height: 1))
        footerBorder.boxType = .separator
        footerBorder.autoresizingMask = [.width, .minYMargin]
        footerView.addSubview(footerBorder)

        statusLabel = NSTextField(labelWithString: "Ready")
        statusLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 16, y: 4, width: footerView.bounds.width - 32, height: 16)
        statusLabel.autoresizingMask = [.width]
        footerView.addSubview(statusLabel)

        // Scroll & Text View
        let editorRect = NSRect(x: 0, y: footerHeight, width: container.bounds.width, height: container.bounds.height - headerHeight - footerHeight)
        scrollView = NSScrollView(frame: editorRect)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let contentSize = scrollView.contentSize
        textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSMakeSize(0.0, contentSize.height)
        textView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.delegate = self
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSMakeSize(10, 10)
        textView.drawsBackground = false

        scrollView.documentView = textView

        // Line Numbers Gutter
        gutterView = LineNumberGutterView(textView: textView)
        scrollView.verticalRulerView = gutterView
        scrollView.rulersVisible = SettingsManager.shared.settings.showLineNumbers

        container.addSubview(scrollView)
    }

    private func resolveEditorColors() -> (textColor: NSColor, bgColor: NSColor) {
        let settings = SettingsManager.shared.settings
        if settings.quickEditorTheme == "dark" {
            return (NSColor(white: 0.92, alpha: 1.0), NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 0.95))
        } else if settings.quickEditorTheme == "light" {
            return (NSColor.black, NSColor(white: 0.98, alpha: 0.95))
        } else {
            // System match
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let textCol = isDark ? NSColor(white: 0.92, alpha: 1.0) : NSColor.textColor
            let bgCol = isDark ? NSColor(white: 0.14, alpha: 0.95) : NSColor(white: 0.98, alpha: 0.95)
            return (textCol, bgCol)
        }
    }

    private func resolveFont() -> NSFont {
        let settings = SettingsManager.shared.settings
        var fontSize = CGFloat(settings.quickEditorFontSize)
        if fontSize < 10 { fontSize = 13 }

        if settings.quickEditorFontFamily == "Menlo" {
            return NSFont(name: "Menlo", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else if settings.quickEditorFontFamily == "Courier New" {
            return NSFont(name: "Courier New", size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        } else {
            return NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }

    private func applySettingsAppearance() {
        let settings = SettingsManager.shared.settings
        let font = resolveFont()
        let colors = resolveEditorColors()

        textView.font = font
        textView.textColor = colors.textColor
        textView.insertionPointColor = colors.textColor

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
    @objc public func openNewDraft() {
        self.currentFileURL = nil
        applySettingsAppearance()

        setTextContent("")
        isModified = false

        titleLabel.stringValue = "Untitled"
        pathLabel.stringValue = "New Scratch Buffer (⌘S to Save)"
        iconImageView.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "File")

        updateOpenWithMenu(forExtension: "txt")
        updateStatusUI()
        presentPanel()
    }

    @objc public func openFile(atPath path: String) {
        let url = URL(fileURLWithPath: path)
        openFile(at: url)
    }

    @objc public func openFile(at url: URL) {
        // If current file has unsaved changes, auto-save before switching to the new selection
        if isModified && currentFileURL != nil {
            saveFile()
        }

        self.currentFileURL = url
        applySettingsAppearance()

        do {
            let data = try Data(contentsOf: url)
            if let content = String(data: data, encoding: .utf8) {
                setTextContent(content)
            } else if let content = String(data: data, encoding: .isoLatin1) {
                setTextContent(content)
            } else {
                setTextContent("// Warning: Binary file or unsupported encoding.\n")
            }
            isModified = false
        } catch {
            NSLog("[MacNewFile] Error reading file: %@", error.localizedDescription)
            setTextContent("// Error reading file: \(error.localizedDescription)")
            isModified = false
        }

        // Update Header UI
        let fileName = url.lastPathComponent
        let dirPath = url.deletingLastPathComponent().path
        titleLabel.stringValue = fileName
        pathLabel.stringValue = dirPath

        // Apple document icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSMakeSize(22, 22)
        iconImageView.image = icon

        updateOpenWithMenu(forExtension: url.pathExtension)
        updateStatusUI()
        presentPanel()
    }

    private func setTextContent(_ content: String) {
        let font = resolveFont()
        let colors = resolveEditorColors()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: colors.textColor
        ]

        let attrString = NSAttributedString(string: content, attributes: attributes)
        textView.textStorage?.setAttributedString(attrString)
        textView.typingAttributes = attributes
        textView.font = font
        textView.textColor = colors.textColor
        textView.needsDisplay = true
        gutterView?.needsDisplay = true
    }

    private func presentPanel() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        textView.window?.makeFirstResponder(textView)
        startSelectionPolling()
    }

    // MARK: - Responsive Finder Selection Polling
    private func startSelectionPolling() {
        selectionPollingTimer?.invalidate()
        selectionPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.checkFinderSelectionChange()
        }
    }

    private func stopSelectionPolling() {
        selectionPollingTimer?.invalidate()
        selectionPollingTimer = nil
    }

    private func checkFinderSelectionChange() {
        guard let window = self.window, window.isVisible else {
            stopSelectionPolling()
            return
        }

        // Only track selection when Finder is the frontmost application
        if let frontApp = NSWorkspace.shared.frontmostApplication, frontApp.bundleIdentifier == "com.apple.finder" {
            if let selectedPath = GlobalHotkeyManager.shared.getFinderSelectedFilePath() {
                let selectedURL = URL(fileURLWithPath: selectedPath)
                if selectedURL.path != currentFileURL?.path {
                    let ext = selectedURL.pathExtension.lowercased()
                    // Only switch if this file type is supported and enabled for Quick Editor!
                    if SettingsManager.shared.isExtensionEnabledForQuickEditor(ext: ext) {
                        openFile(at: selectedURL)
                    }
                }
            }
        }
    }

    // MARK: - Compatible Apps Discovery & Selection
    private func updateOpenWithMenu(forExtension ext: String) {
        openWithButton.removeAllItems()
        compatibleApps.removeAll()

        guard let url = currentFileURL else {
            openWithButton.addItem(withTitle: "Open in App")
            openWithButton.isEnabled = false
            return
        }

        openWithButton.isEnabled = true
        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: url)
        self.compatibleApps = appURLs

        let (preferredBundleId, _) = SettingsManager.shared.getPreferredApp(forExtension: ext)

        var selectedIndex = 0
        for (index, appURL) in appURLs.enumerated() {
            let bundle = Bundle(url: appURL)
            let appName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            let item = NSMenuItem(title: "Open with \(appName)", action: nil, keyEquivalent: "")
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSMakeSize(16, 16)
            item.image = icon
            item.representedObject = appURL

            openWithButton.menu?.addItem(item)

            if let preferred = preferredBundleId, bundle?.bundleIdentifier == preferred {
                selectedIndex = index
            }
        }

        if openWithButton.numberOfItems == 0 {
            openWithButton.addItem(withTitle: "Open with Default")
        } else {
            openWithButton.selectItem(at: selectedIndex)
        }
    }

    @objc private func handleOpenWithSelection(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem,
              let appURL = selectedItem.representedObject as? URL,
              let fileURL = currentFileURL else {
            if let fileURL = currentFileURL {
                NSWorkspace.shared.open(fileURL)
            }
            return
        }

        // Save preference for this extension
        let bundle = Bundle(url: appURL)
        let appName = selectedItem.title.replacingOccurrences(of: "Open with ", with: "")
        SettingsManager.shared.setPreferredApp(
            bundleId: bundle?.bundleIdentifier,
            name: appName,
            forExtension: fileURL.pathExtension
        )

        // Open file in chosen app
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: config, completionHandler: nil)
    }

    @objc public func openInCurrentPreferredApp() {
        if let selectedItem = openWithButton.selectedItem,
           let appURL = selectedItem.representedObject as? URL,
           let fileURL = currentFileURL {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: config, completionHandler: nil)
        } else if let fileURL = currentFileURL {
            NSWorkspace.shared.open(fileURL)
        }
    }

    // MARK: - Actions
    @objc public func saveFile() {
        guard let url = currentFileURL else {
            let savePanel = NSSavePanel()
            savePanel.title = "Save New File"
            savePanel.nameFieldStringValue = "Untitled.txt"
            if savePanel.runModal() == .OK, let targetURL = savePanel.url {
                self.currentFileURL = targetURL
                titleLabel.stringValue = targetURL.lastPathComponent
                pathLabel.stringValue = targetURL.deletingLastPathComponent().path
                saveFile()
            }
            return
        }

        do {
            let content = textView.string
            try content.write(to: url, atomically: true, encoding: .utf8)
            isModified = false

            saveIndicatorLabel.stringValue = "Saved ✓"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if !(self?.isModified ?? false) {
                    self?.saveIndicatorLabel.stringValue = ""
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to Save File"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    @objc public func closeWindow() {
        window?.orderOut(nil)
        stopSelectionPolling()
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

        statusLabel.stringValue = "\(lineCount) lines, \(charCount) chars  •  UTF-8  •  \(ext)"
        saveIndicatorLabel.stringValue = isModified ? "● Modified" : ""
    }

    // MARK: - Window Delegate
    public func windowWillClose(_ notification: Notification) {
        stopSelectionPolling()
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isModified {
            let alert = NSAlert()
            alert.messageText = "Save changes before closing?"
            alert.informativeText = "Changes to \"\(currentFileURL?.lastPathComponent ?? "file")\" will be lost if you don't save."
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
