import Cocoa
import SwiftUI
import UniformTypeIdentifiers

public class EditorDocument {
    public var fileURL: URL
    public var content: String
    public var isModified: Bool

    public init(fileURL: URL, content: String) {
        self.fileURL = fileURL
        self.content = content
        self.isModified = false
    }
}

@objc(QuickEditorWindowController)
public class QuickEditorWindowController: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    @objc(sharedController)
    public static let shared = QuickEditorWindowController()

    public private(set) var documents: [EditorDocument] = []
    public private(set) var activeIndex: Int = 0

    public var currentFileURL: URL? {
        guard activeIndex >= 0 && activeIndex < documents.count else { return nil }
        return documents[activeIndex].fileURL
    }

    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var gutterView: LineNumberGutterView?
    private var backgroundVisualEffect: NSVisualEffectView!
    private var headerView: NSView!
    private var tabBarScrollView: NSScrollView!
    private var tabBarContainer: NSView!
    private var footerView: NSView!

    private var titleLabel: NSTextField!
    private var pathLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var saveIndicatorLabel: NSTextField!
    private var iconImageView: NSImageView!
    private var openWithButton: NSPopUpButton!

    private var selectionPollingTimer: Timer?
    private var compatibleApps: [URL] = []

    private let headerHeight: CGFloat = 44.0
    private let tabBarHeight: CGFloat = 30.0
    private let footerHeight: CGFloat = 24.0

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 530),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
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

        // 1. Top Header Bar (Quick Look style)
        headerView = NSView(frame: NSRect(x: 0, y: container.bounds.height - headerHeight, width: container.bounds.width, height: headerHeight))
        headerView.autoresizingMask = [.width, .minYMargin]
        container.addSubview(headerView)

        // File icon
        iconImageView = NSImageView(frame: NSRect(x: 64, y: 11, width: 22, height: 22))
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        headerView.addSubview(iconImageView)

        // Title and Folder path
        titleLabel = NSTextField(labelWithString: "Untitled")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 92, y: 21, width: 320, height: 18)
        titleLabel.autoresizingMask = [.width]
        headerView.addSubview(titleLabel)

        pathLabel = NSTextField(labelWithString: "")
        pathLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.frame = NSRect(x: 92, y: 6, width: 320, height: 15)
        pathLabel.autoresizingMask = [.width]
        headerView.addSubview(pathLabel)

        // Save Status Indicator
        saveIndicatorLabel = NSTextField(labelWithString: "")
        saveIndicatorLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        saveIndicatorLabel.textColor = .secondaryLabelColor
        saveIndicatorLabel.alignment = .right
        saveIndicatorLabel.frame = NSRect(x: headerView.bounds.width - 340, y: 14, width: 100, height: 16)
        saveIndicatorLabel.autoresizingMask = [.minXMargin, .minYMargin]
        headerView.addSubview(saveIndicatorLabel)

        // "Open with..." PopUp Menu Button
        openWithButton = NSPopUpButton(frame: NSRect(x: headerView.bounds.width - 230, y: 9, width: 215, height: 26), pullsDown: false)
        openWithButton.bezelStyle = .rounded
        openWithButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        openWithButton.autoresizingMask = [.minXMargin, .minYMargin]
        openWithButton.target = self
        openWithButton.action = #selector(handleOpenWithSelection(_:))
        headerView.addSubview(openWithButton)

        // Header separator
        let headerBorder = NSBox(frame: NSRect(x: 0, y: 0, width: headerView.bounds.width, height: 1))
        headerBorder.boxType = .separator
        headerBorder.autoresizingMask = [.width, .maxYMargin]
        headerView.addSubview(headerBorder)

        // 2. Multi-Tab Bar (shown when documents.count > 1)
        tabBarScrollView = NSScrollView(frame: NSRect(x: 0, y: container.bounds.height - headerHeight - tabBarHeight, width: container.bounds.width, height: tabBarHeight))
        tabBarScrollView.autoresizingMask = [.width, .minYMargin]
        tabBarScrollView.hasHorizontalScroller = false
        tabBarScrollView.hasVerticalScroller = false
        tabBarScrollView.drawsBackground = false
        tabBarScrollView.borderType = .noBorder
        tabBarScrollView.isHidden = true

        tabBarContainer = NSView(frame: NSRect(x: 0, y: 0, width: container.bounds.width, height: tabBarHeight))
        tabBarScrollView.documentView = tabBarContainer
        container.addSubview(tabBarScrollView)

        // 3. Bottom Status Bar
        footerView = NSView(frame: NSRect(x: 0, y: 0, width: container.bounds.width, height: footerHeight))
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

        // 4. Middle Scroll & Text View
        scrollView = NSScrollView(frame: calculateEditorRect())
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
        textView.textContainerInset = NSMakeSize(12, 12)
        textView.drawsBackground = false

        scrollView.documentView = textView

        // Line Numbers Gutter
        gutterView = LineNumberGutterView(textView: textView)
        scrollView.verticalRulerView = gutterView
        scrollView.rulersVisible = SettingsManager.shared.settings.showLineNumbers

        container.addSubview(scrollView)
    }

    private func calculateEditorRect() -> NSRect {
        guard let container = backgroundVisualEffect else { return .zero }
        let isMultiTab = documents.count > 1
        let topOffset = headerHeight + (isMultiTab ? tabBarHeight : 0)
        let height = max(100, container.bounds.height - topOffset - footerHeight)
        return NSRect(x: 0, y: footerHeight, width: container.bounds.width, height: height)
    }

    private func updateLayoutForTabs() {
        let isMultiTab = documents.count > 1
        tabBarScrollView.isHidden = !isMultiTab
        scrollView.frame = calculateEditorRect()

        if isMultiTab {
            rebuildTabBar()
        }
    }

    private func rebuildTabBar() {
        tabBarContainer.subviews.removeAll()

        var currentX: CGFloat = 8.0
        let tabHeight: CGFloat = 24.0
        let tabSpacing: CGFloat = 6.0

        for (index, doc) in documents.enumerated() {
            let isActive = (index == activeIndex)
            let fileName = doc.fileURL.lastPathComponent

            // Tab button view
            let tabWidth: CGFloat = min(160, max(100, CGFloat(fileName.count * 8 + 48)))
            let tabFrame = NSRect(x: currentX, y: 3, width: tabWidth, height: tabHeight)
            let tabView = NSView(frame: tabFrame)

            // Background layer
            let bgLayer = CALayer()
            bgLayer.frame = tabView.bounds
            bgLayer.cornerRadius = 6
            if isActive {
                bgLayer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
                bgLayer.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.5).cgColor
                bgLayer.borderWidth = 1
            } else {
                bgLayer.backgroundColor = NSColor(white: 0.2, alpha: 0.35).cgColor
            }
            tabView.wantsLayer = true
            tabView.layer?.addSublayer(bgLayer)

            // Tab click button
            let clickButton = NSButton(frame: tabView.bounds)
            clickButton.title = ""
            clickButton.isBordered = false
            clickButton.tag = index
            clickButton.target = self
            clickButton.action = #selector(handleTabClick(_:))
            tabView.addSubview(clickButton)

            // File Icon
            let iconView = NSImageView(frame: NSRect(x: 8, y: 4, width: 16, height: 16))
            let icon = NSWorkspace.shared.icon(forFile: doc.fileURL.path)
            icon.size = NSMakeSize(16, 16)
            iconView.image = icon
            tabView.addSubview(iconView)

            // File Name Label
            let dirtyPrefix = doc.isModified ? "● " : ""
            let nameLabel = NSTextField(labelWithString: "\(dirtyPrefix)\(fileName)")
            nameLabel.font = NSFont.systemFont(ofSize: 11, weight: isActive ? .semibold : .regular)
            nameLabel.textColor = isActive ? .labelColor : .secondaryLabelColor
            nameLabel.frame = NSRect(x: 28, y: 4, width: tabWidth - 48, height: 16)
            nameLabel.lineBreakMode = .byTruncatingTail
            tabView.addSubview(nameLabel)

            // Close 'x' button
            let closeBtn = NSButton(frame: NSRect(x: tabWidth - 20, y: 4, width: 16, height: 16))
            closeBtn.isBordered = false
            if #available(macOS 11.0, *) {
                closeBtn.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Tab")
            } else {
                closeBtn.title = "×"
            }
            closeBtn.tag = index
            closeBtn.target = self
            closeBtn.action = #selector(handleTabClose(_:))
            tabView.addSubview(closeBtn)

            tabBarContainer.addSubview(tabView)
            currentX += tabWidth + tabSpacing
        }

        tabBarContainer.frame = NSRect(x: 0, y: 0, width: max(tabBarScrollView.bounds.width, currentX + 16), height: tabBarHeight)
    }

    @objc private func handleTabClick(_ sender: NSButton) {
        let index = sender.tag
        switchToTab(index: index)
    }

    @objc private func handleTabClose(_ sender: NSButton) {
        let index = sender.tag
        closeTab(at: index)
    }

    public func switchToTab(index: Int) {
        guard index >= 0 && index < documents.count else { return }

        // Save current editor text into the departing document
        if activeIndex >= 0 && activeIndex < documents.count {
            documents[activeIndex].content = textView.string
        }

        activeIndex = index
        let doc = documents[activeIndex]
        loadDocumentIntoEditor(doc)
        updateLayoutForTabs()
    }

    public func closeTab(at index: Int) {
        guard index >= 0 && index < documents.count else { return }

        let doc = documents[index]
        if doc.isModified {
            let alert = NSAlert()
            alert.messageText = "Save changes before closing?"
            alert.informativeText = "Changes to \"\(doc.fileURL.lastPathComponent)\" will be lost if you don't save."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                saveDocument(doc)
            } else if response == .alertThirdButtonReturn {
                return
            }
        }

        documents.remove(at: index)

        if documents.isEmpty {
            closeWindow()
            return
        }

        if activeIndex >= documents.count {
            activeIndex = documents.count - 1
        }
        switchToTab(index: activeIndex)
    }

    // MARK: - Open Multiple Files (Multi-Tab)
    @objc public func openFiles(at paths: [String]) {
        let validURLs = paths.compactMap { URL(fileURLWithPath: $0) }
        openURLs(validURLs)
    }

    public func openURLs(_ urls: [URL]) {
        guard !urls.isEmpty else {
            closeWindow()
            return
        }

        // Auto-save currently active modified file before reloading
        if activeIndex >= 0 && activeIndex < documents.count && documents[activeIndex].isModified {
            saveDocument(documents[activeIndex])
        }

        var newDocs: [EditorDocument] = []
        for url in urls {
            let content: String
            do {
                let data = try Data(contentsOf: url)
                if let str = String(data: data, encoding: .utf8) {
                    content = str
                } else if let str = String(data: data, encoding: .isoLatin1) {
                    content = str
                } else {
                    content = "// Binary or unsupported encoding.\n"
                }
            } catch {
                content = "// Error: \(error.localizedDescription)\n"
            }
            newDocs.append(EditorDocument(fileURL: url, content: content))
        }

        self.documents = newDocs
        self.activeIndex = 0

        if let first = documents.first {
            loadDocumentIntoEditor(first)
        }

        updateLayoutForTabs()
        presentPanel()
    }

    // MARK: - Open Single File
    @objc public func openFile(atPath path: String) {
        openFiles(at: [path])
    }

    @objc public func openFile(at url: URL) {
        openURLs([url])
    }

    private func loadDocumentIntoEditor(_ doc: EditorDocument) {
        applySettingsAppearance()
        setTextContent(doc.content)

        titleLabel.stringValue = doc.fileURL.lastPathComponent
        pathLabel.stringValue = doc.fileURL.deletingLastPathComponent().path

        let icon = NSWorkspace.shared.icon(forFile: doc.fileURL.path)
        icon.size = NSMakeSize(22, 22)
        iconImageView.image = icon

        updateOpenWithMenu(forExtension: doc.fileURL.pathExtension)
        updateStatusUI()
    }

    private func resolveEditorColors() -> (textColor: NSColor, bgColor: NSColor) {
        let settings = SettingsManager.shared.settings
        if settings.quickEditorTheme == "dark" {
            return (NSColor(white: 0.94, alpha: 1.0), NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 0.95))
        } else if settings.quickEditorTheme == "light" {
            return (NSColor.black, NSColor(white: 0.98, alpha: 0.95))
        } else {
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let textCol = isDark ? NSColor(white: 0.94, alpha: 1.0) : NSColor.textColor
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

    // MARK: - Responsive Finder Selection Polling (Auto-Close When Incompatible or None)
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
            let eligiblePaths = GlobalHotkeyManager.shared.getEligibleFinderSelectedPaths()

            // 1. AUTO-CLOSE: If no item is selected or selection is incompatible/disabled, CLOSE immediately!
            if eligiblePaths.isEmpty {
                closeWindow()
                return
            }

            // 2. Check if selected paths differ from our currently open documents
            let currentPaths = documents.map { $0.fileURL.path }
            if eligiblePaths != currentPaths {
                openFiles(at: eligiblePaths)
            }
        }
    }

    // MARK: - Open With App Selection
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

        let bundle = Bundle(url: appURL)
        let appName = selectedItem.title.replacingOccurrences(of: "Open with ", with: "")
        SettingsManager.shared.setPreferredApp(
            bundleId: bundle?.bundleIdentifier,
            name: appName,
            forExtension: fileURL.pathExtension
        )

        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: config, completionHandler: nil)
    }

    // MARK: - Actions
    @objc public func saveFile() {
        guard activeIndex >= 0 && activeIndex < documents.count else { return }
        let doc = documents[activeIndex]
        doc.content = textView.string
        saveDocument(doc)
    }

    private func saveDocument(_ doc: EditorDocument) {
        do {
            try doc.content.write(to: doc.fileURL, atomically: true, encoding: .utf8)
            doc.isModified = false
            saveIndicatorLabel.stringValue = "Saved ✓"
            updateStatusUI()
            rebuildTabBar()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.activeIndex ?? -1 < self?.documents.count ?? 0,
                   !(self?.documents[self?.activeIndex ?? 0].isModified ?? false) {
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
        documents.removeAll()
        activeIndex = 0
    }

    public func textDidChange(_ notification: Notification) {
        if activeIndex >= 0 && activeIndex < documents.count {
            documents[activeIndex].isModified = true
            documents[activeIndex].content = textView.string
        }
        gutterView?.needsDisplay = true
        updateStatusUI()
        rebuildTabBar()
    }

    private func updateStatusUI() {
        guard activeIndex >= 0 && activeIndex < documents.count else {
            statusLabel.stringValue = "Ready"
            saveIndicatorLabel.stringValue = ""
            return
        }

        let doc = documents[activeIndex]
        let lineCount = doc.content.isEmpty ? 1 : doc.content.components(separatedBy: "\n").count
        let charCount = doc.content.count
        let ext = doc.fileURL.pathExtension.uppercased()

        let tabInfo = documents.count > 1 ? "Tab \(activeIndex + 1) of \(documents.count)  •  " : ""
        statusLabel.stringValue = "\(tabInfo)\(lineCount) lines, \(charCount) chars  •  UTF-8  •  \(ext)"
        saveIndicatorLabel.stringValue = doc.isModified ? "● Modified" : ""
    }

    // MARK: - Window Delegate
    public func windowWillClose(_ notification: Notification) {
        stopSelectionPolling()
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        for doc in documents where doc.isModified {
            let alert = NSAlert()
            alert.messageText = "Save changes before closing?"
            alert.informativeText = "Changes to \"\(doc.fileURL.lastPathComponent)\" will be lost if you don't save."
            alert.addButton(withTitle: "Save All")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                for d in documents where d.isModified {
                    saveDocument(d)
                }
                return true
            } else if response == .alertSecondButtonReturn {
                return true
            } else {
                return false
            }
        }
        return true
    }
}
