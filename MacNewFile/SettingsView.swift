import SwiftUI

public class SettingsViewModel: ObservableObject {
    @Published public var selectedTab: Int = 0
    @Published public var searchText: String = ""
    @Published public var selectedCategory: String = "All"
    @Published public var isShowingAddSheet: Bool = false

    // Form states for adding custom type
    @Published public var newExt: String = ""
    @Published public var newName: String = ""
    @Published public var newCategory: String = "Code & Web"
    @Published public var newTemplate: String = ""

    public init() {}

    public func clearAddForm() {
        newExt = ""
        newName = ""
        newCategory = "Code & Web"
        newTemplate = ""
    }
}

public struct SettingsView: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var viewModel = SettingsViewModel()

    private let popularCodingFonts = [
        "SF Mono", "Menlo", "Monaco", "Courier New", "Courier",
        "Andale Mono", "PT Mono", "Fira Code", "JetBrains Mono",
        "Source Code Pro", "Cascadia Code", "Hack"
    ]

    private var allSystemFonts: [String] {
        return NSFontManager.shared.availableFontFamilies.sorted()
    }

    private let availableTerminals = [
        "Terminal", "iTerm", "Warp", "Ghostty", "Alacritty", "kitty", "Custom"
    ]

    private var categories: [String] {
        var set = Set<String>()
        for item in settingsManager.settings.fileItems {
            set.insert(item.category)
        }
        var list = ["All"]
        list.append(contentsOf: set.sorted())
        return list
    }

    private var filteredItems: [FileItem] {
        settingsManager.settings.fileItems.filter { item in
            let matchesCategory = (viewModel.selectedCategory == "All" || item.category == viewModel.selectedCategory)
            let matchesSearch = viewModel.searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
                item.ext.localizedCaseInsensitiveContains(viewModel.searchText) ||
                item.category.localizedCaseInsensitiveContains(viewModel.searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var newFileActiveCount: Int {
        settingsManager.settings.fileItems.filter { $0.enabledForNewFile }.count
    }

    private var quickEditorActiveCount: Int {
        settingsManager.settings.fileItems.filter { $0.enabledForQuickEditor }.count
    }

    public init() {}

    public var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            fileTypesTab
                .tabItem {
                    Label("File Types", systemImage: "doc.badge.plus")
                }
                .tag(0)

            quickEditorTab
                .tabItem {
                    Label("Quick Editor", systemImage: "eye.fill")
                }
                .tag(1)

            terminalTab
                .tabItem {
                    Label("Terminal", systemImage: "terminal.fill")
                }
                .tag(2)

            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(minWidth: 740, idealWidth: 780, minHeight: 540, idealHeight: 580)
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            addCustomTypeSheet
        }
    }

    // MARK: - File Types Tab
    private var fileTypesTab: some View {
        VStack(spacing: 0) {
            // Header Stats & Search
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    Image(systemName: "slider.horizontal.2.square.badge.arrow.down")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("File Type Enablement")
                            .font(.headline)
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.square.fill")
                                    .foregroundColor(.blue)
                                Text("New File: \(newFileActiveCount) enabled")
                            }
                            Text("•").foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(.purple)
                                Text("Quick Editor: \(quickEditorActiveCount) enabled")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { viewModel.isShowingAddSheet = true }) {
                        Label("Add Custom Type", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                // Search & Category Picker
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search name or extension...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
                .padding(.horizontal, 16)

                // Column Headers & Bulk Controls
                HStack {
                    HStack(spacing: 12) {
                        Menu("New File...") {
                            Button("Enable All") { settingsManager.setAllNewFile(enabled: true) }
                            Button("Disable All") { settingsManager.setAllNewFile(enabled: false) }
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()

                        Menu("Quick Editor...") {
                            Button("Enable All") { settingsManager.setAllQuickEditor(enabled: true) }
                            Button("Disable All") { settingsManager.setAllQuickEditor(enabled: false) }
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()

                        Button("Reset Defaults") {
                            settingsManager.resetToDefaults()
                        }
                        .buttonStyle(.link)
                    }
                    .font(.caption)

                    Spacer()

                    // Column legend
                    HStack(spacing: 24) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.square")
                            Text("New File")
                        }
                        .frame(width: 75, alignment: .trailing)

                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("Quick Edit")
                        }
                        .frame(width: 75, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // List of File Items
            List {
                ForEach(filteredItems) { item in
                    fileItemRow(item)
                }
            }
            .listStyle(.inset)
        }
    }

    private func fileItemRow(_ item: FileItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor((item.enabledForNewFile || item.enabledForQuickEditor) ? .accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(".\(item.ext)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.18))
                        .cornerRadius(4)
                }

                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let appName = item.customAppName, !appName.isEmpty {
                        Text("Opens in \(appName)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    if item.isCustom {
                        Text("CUSTOM")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
            }

            Spacer()

            if item.isCustom {
                Button(action: {
                    settingsManager.removeFileItem(id: item.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete custom file type")
                .padding(.trailing, 4)
            }

            // Toggle 1: New File
            Toggle("", isOn: Binding(
                get: { item.enabledForNewFile },
                set: { newValue in
                    settingsManager.toggleNewFile(id: item.id, enabled: newValue)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help("Enable in Finder right-click New File menu")
            .frame(width: 75, alignment: .trailing)

            // Toggle 2: Quick Editor
            Toggle("", isOn: Binding(
                get: { item.enabledForQuickEditor },
                set: { newValue in
                    settingsManager.toggleQuickEditor(id: item.id, enabled: newValue)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help("Enable preview and editing with Option+Space")
            .frame(width: 75, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Quick Editor Tab
    private var quickEditorTab: some View {
        Form {
            Section(header: Text("Activation & Experience").font(.headline)) {
                Picker("Global Shortcut:", selection: $settingsManager.settings.quickEditorShortcut) {
                    Text("Option + Space (⌥ Space)").tag("Option+Space")
                    Text("Command + Shift + E (⌘⇧E)").tag("Cmd+Shift+E")
                    Text("Control + Option + N (⌃⌥N)").tag("Ctrl+Opt+N")
                    Text("Command + Option + E (⌘⌥E)").tag("Cmd+Opt+E")
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Press shortcut on any supported file in Finder to preview and edit in-place.")
                    Text("• Repeating shortcut or clicking empty space closes preview (like macOS Quick Look).")
                    Text("• Multi-selection in Finder opens an editable multi-tab bar for all selected items.")
                    Text("• Moving arrow keys in Finder dynamically updates the preview to the selected file.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)

                Toggle("Fluid Quick Look opening & closing animations", isOn: $settingsManager.settings.enableQuickLookAnimation)
                Toggle("Show \"Quick Edit File\" in Finder right-click menu", isOn: $settingsManager.settings.showQuickEditInMenu)
            }

            Section(header: Text("Typography & Appearance").font(.headline)) {
                Picker("Font Family:", selection: $settingsManager.settings.quickEditorFontFamily) {
                    Section(header: Text("Coding & Monospace")) {
                        ForEach(popularCodingFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }

                    Section(header: Text("All Installed System Fonts")) {
                        ForEach(allSystemFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Font Size:")
                    Slider(value: $settingsManager.settings.quickEditorFontSize, in: 11...22, step: 1)
                    Text("\(Int(settingsManager.settings.quickEditorFontSize)) pt")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 45)
                }

                Picker("Theme:", selection: $settingsManager.settings.quickEditorTheme) {
                    Text("System Match").tag("system")
                    Text("VS Code Dark Modern").tag("dark")
                    Text("Light").tag("light")
                }
                .pickerStyle(.segmented)

                Toggle("Show Line Numbers in Gutter", isOn: $settingsManager.settings.showLineNumbers)
                Toggle("Soft Word Wrap", isOn: $settingsManager.settings.wordWrap)
            }
        }
        .padding(20)
    }

    // MARK: - Terminal Tab
    private var terminalTab: some View {
        Form {
            Section(header: Text("Terminal Application").font(.headline)) {
                Text("Select your preferred terminal app to launch when using 'Open in Terminal' from Finder.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Terminal App:", selection: $settingsManager.settings.terminalApp) {
                    ForEach(availableTerminals, id: \.self) { term in
                        Text(term == "kitty" ? "Kitty" : term).tag(term)
                    }
                }
                .pickerStyle(.menu)

                if settingsManager.settings.terminalApp == "Custom" {
                    HStack {
                        TextField("App name or path:", text: Binding(
                            get: { settingsManager.settings.terminalAppCustomPath ?? "" },
                            set: { settingsManager.settings.terminalAppCustomPath = $0 }
                        ))
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.application]
                            if panel.runModal() == .OK, let url = panel.url {
                                settingsManager.settings.terminalAppCustomPath = url.path
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Test Terminal Launch") {
                        testLaunchTerminal()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
    }

    private func testLaunchTerminal() {
        let app = settingsManager.settings.terminalApp
        let custom = settingsManager.settings.terminalAppCustomPath
        let home = NSHomeDirectory()

        let script: String
        if app == "Custom", let c = custom, !c.isEmpty {
            script = "do shell script \"open -a '\(c)' '\(home)'\""
        } else {
            script = "do shell script \"open -a '\(app)' '\(home)'\""
        }
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section(header: Text("Finder Context Menu").font(.headline)) {
                Toggle("Group \"New File\" Menu by Category", isOn: $settingsManager.settings.groupByCategory)
                Text("When enabled, groups enabled items into submenus (Code & Web, Documents, etc.). When disabled, displays them in a clean list.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Include \"Copy Path\" item", isOn: $settingsManager.settings.includeCopyPath)
                Toggle("Include \"Open Terminal\" item", isOn: $settingsManager.settings.includeOpenTerminal)
            }

            Section(header: Text("System Integration").font(.headline)) {
                Toggle("Launch MacNewFile at Login", isOn: $settingsManager.settings.launchAtLogin)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finder Extension Status")
                            .font(.system(size: 13, weight: .medium))
                        Text("Active and integrated with macOS Finder.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Restart Extension") {
                        reRegisterExtension()
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - Add Custom Type Sheet
    private var addCustomTypeSheet: some View {
        VStack(spacing: 16) {
            Text("Add Custom File Type")
                .font(.headline)

            Form {
                TextField("File Extension (e.g. vue, svelte, dart):", text: $viewModel.newExt)
                TextField("Display Name (e.g. Vue Component):", text: $viewModel.newName)

                Picker("Category:", selection: $viewModel.newCategory) {
                    Text("Code & Web").tag("Code & Web")
                    Text("Documents & Notes").tag("Documents & Notes")
                    Text("Data & Config").tag("Data & Config")
                    Text("Custom").tag("Custom")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Template / Boilerplate Content:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.newTemplate)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 120)
                        .border(Color.gray.opacity(0.3), width: 1)
                }
            }

            HStack {
                Button("Cancel") {
                    viewModel.isShowingAddSheet = false
                    viewModel.clearAddForm()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add File Type") {
                    settingsManager.addCustomFileItem(
                        name: viewModel.newName,
                        ext: viewModel.newExt,
                        category: viewModel.newCategory,
                        template: viewModel.newTemplate
                    )
                    viewModel.isShowingAddSheet = false
                    viewModel.clearAddForm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newExt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480, height: 360)
    }

    private func reRegisterExtension() {
        let task = Process()
        task.launchPath = "/usr/bin/pluginkit"
        task.arguments = ["-e", "use", "-i", "com.louieyin.MacNewFile.MacNewFileFinderExtension"]
        try? task.run()
    }
}
