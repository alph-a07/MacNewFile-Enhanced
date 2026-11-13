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

    private var categorizedFilteredItems: [(category: String, items: [FileItem])] {
        let items = filteredItems
        if viewModel.selectedCategory != "All" {
            return [(category: viewModel.selectedCategory, items: items)]
        }
        let order = ["Code & Web", "Documents & Notes", "Data & Config", "Custom"]
        var result: [(category: String, items: [FileItem])] = []
        for cat in order {
            let catItems = items.filter { $0.category == cat }
            if !catItems.isEmpty {
                result.append((category: cat, items: catItems))
            }
        }
        let remaining = items.filter { !order.contains($0.category) }
        if !remaining.isEmpty {
            result.append((category: "Other", items: remaining))
        }
        return result
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
        .frame(width: 700, height: 530)
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            addCustomTypeSheet
        }
    }

    // MARK: - File Types Tab (Clean, Un-overwhelming, Categorized Table)
    private var fileTypesTab: some View {
        VStack(spacing: 0) {
            // Clean Top Controls Bar
            HStack(spacing: 10) {
                // Search Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search file types...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                // Category Filter
                Picker("", selection: $viewModel.selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)

                // Manage Menu (Bulk Actions & Reset)
                Menu {
                    Section("New File Action") {
                        Button("Enable All") { settingsManager.setAllNewFile(enabled: true) }
                        Button("Disable All") { settingsManager.setAllNewFile(enabled: false) }
                    }
                    Section("Quick Editor Action") {
                        Button("Enable All") { settingsManager.setAllQuickEditor(enabled: true) }
                        Button("Disable All") { settingsManager.setAllQuickEditor(enabled: false) }
                    }
                    Divider()
                    Button("Reset to Defaults") {
                        settingsManager.resetToDefaults()
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)

                // Add Custom Type Button
                Button(action: { viewModel.isShowingAddSheet = true }) {
                    Label("Add Type", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            // Subtle summary bar
            HStack {
                Text("\(filteredItems.count) types  •  \(newFileActiveCount) in New File  •  \(quickEditorActiveCount) in Quick Editor")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 16) {
                    Text("New File")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)

                    Text("Quick Edit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // List of Grouped File Items with Clean Checkboxes
            List {
                ForEach(categorizedFilteredItems, id: \.category) { section in
                    Section(header: Text(section.category).font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)) {
                        ForEach(section.items) { item in
                            fileItemRow(item)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func fileItemRow(_ item: FileItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(".\(item.ext)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color(NSColor.quaternaryLabelColor))
                        .cornerRadius(4)

                    if item.isCustom {
                        Text("CUSTOM")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(3)
                    }
                }

                if let appName = item.customAppName, !appName.isEmpty {
                    Text("Opens in \(appName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if item.isCustom {
                Button(action: {
                    settingsManager.removeFileItem(id: item.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete custom file type")
                .padding(.trailing, 8)
            }

            // Dual Native macOS Checkboxes (Calm, Standard, Non-Overwhelming)
            HStack(spacing: 16) {
                Toggle("", isOn: Binding(
                    get: { item.enabledForNewFile },
                    set: { newValue in
                        settingsManager.toggleNewFile(id: item.id, enabled: newValue)
                    }
                ))
                .toggleStyle(.checkbox)
                .help("Enable in Finder New File right-click menu")
                .frame(width: 80, alignment: .leading)

                Toggle("", isOn: Binding(
                    get: { item.enabledForQuickEditor },
                    set: { newValue in
                        settingsManager.toggleQuickEditor(id: item.id, enabled: newValue)
                    }
                ))
                .toggleStyle(.checkbox)
                .help("Enable preview and editing with Option+Space")
                .frame(width: 80, alignment: .leading)
            }
            .padding(.trailing, 4)
        }
        .padding(.vertical, 3)
    }

    // MARK: - Quick Editor Tab (Grouped Modern Apple Cards)
    private var quickEditorTab: some View {
        Form {
            Section(
                header: Text("Activation & Shortcuts"),
                footer: Text("Press the shortcut on any supported file in Finder to preview and edit in-place. Repeating the shortcut or clicking outside closes the editor.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                Picker("Global Shortcut", selection: $settingsManager.settings.quickEditorShortcut) {
                    Text("Option + Space (⌥ Space)").tag("Option+Space")
                    Text("Command + Shift + E (⌘⇧E)").tag("Cmd+Shift+E")
                    Text("Control + Option + N (⌃⌥N)").tag("Ctrl+Opt+N")
                    Text("Command + Option + E (⌘⌥E)").tag("Cmd+Opt+E")
                }

                Toggle("Fluid Quick Look zoom animation", isOn: $settingsManager.settings.enableQuickLookAnimation)
                Toggle("Show \"Quick Edit File\" in Finder right-click menu", isOn: $settingsManager.settings.showQuickEditInMenu)
            }

            Section(header: Text("Appearance & Theme")) {
                Picker("Theme", selection: $settingsManager.settings.quickEditorTheme) {
                    Text("System Match").tag("system")
                    Text("Dark Modern").tag("dark")
                    Text("Light").tag("light")
                }
                .pickerStyle(.segmented)

                Toggle("Show line numbers in gutter", isOn: $settingsManager.settings.showLineNumbers)
                Toggle("Soft word wrap", isOn: $settingsManager.settings.wordWrap)
            }

            Section(header: Text("Typography")) {
                Picker("Font Family", selection: $settingsManager.settings.quickEditorFontFamily) {
                    Section("Popular Coding Fonts") {
                        ForEach(popularCodingFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    Section("All Installed System Fonts") {
                        ForEach(allSystemFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $settingsManager.settings.quickEditorFontSize, in: 10...22, step: 1)
                        .frame(width: 180)
                    Text("\(Int(settingsManager.settings.quickEditorFontSize)) pt")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 45, alignment: .trailing)
                }

                // Live Editor Preview Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Preview")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("1").foregroundColor(.secondary).frame(width: 16, alignment: .trailing)
                            Text("// MacNewFile Quick Editor").foregroundColor(.green)
                        }
                        HStack(spacing: 8) {
                            Text("2").foregroundColor(.secondary).frame(width: 16, alignment: .trailing)
                            Text("func edit(file: String) -> Bool {").foregroundColor(.primary)
                        }
                        HStack(spacing: 8) {
                            Text("3").foregroundColor(.secondary).frame(width: 16, alignment: .trailing)
                            Text("    return inPlacePreview()").foregroundColor(.cyan)
                        }
                        HStack(spacing: 8) {
                            Text("4").foregroundColor(.secondary).frame(width: 16, alignment: .trailing)
                            Text("}").foregroundColor(.primary)
                        }
                    }
                    .font(previewFont)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(previewBgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    private var previewFont: Font {
        let size = CGFloat(settingsManager.settings.quickEditorFontSize)
        let name = settingsManager.settings.quickEditorFontFamily
        if name == "SF Mono" {
            return .system(size: size, design: .monospaced)
        }
        return .custom(name, size: size)
    }

    private var previewBgColor: Color {
        if settingsManager.settings.quickEditorTheme == "dark" {
            return Color(red: 0.12, green: 0.12, blue: 0.14)
        } else if settingsManager.settings.quickEditorTheme == "light" {
            return Color(white: 0.96)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }

    // MARK: - Terminal Tab (Grouped Modern Apple Cards)
    private var terminalTab: some View {
        Form {
            Section(
                header: Text("Terminal Application"),
                footer: Text("When selecting 'Open in \(settingsManager.settings.terminalApp)' from Finder, this application will open directly at the targeted folder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                Picker("Terminal App", selection: $settingsManager.settings.terminalApp) {
                    ForEach(availableTerminals, id: \.self) { term in
                        Text(term == "kitty" ? "Kitty" : term).tag(term)
                    }
                }

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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch Verification")
                            .font(.system(size: 13, weight: .medium))
                        Text("Verify that \(settingsManager.settings.terminalApp) launches correctly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Test Launch") {
                        testLaunchTerminal()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("Context Menu Integration")) {
                Toggle("Include \"Open in \(settingsManager.settings.terminalApp)\" in Finder menu", isOn: $settingsManager.settings.includeOpenTerminal)
            }
        }
        .formStyle(.grouped)
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

    // MARK: - General Tab (Grouped Modern Apple Cards)
    private var generalTab: some View {
        Form {
            Section(
                header: Text("Finder Context Menu"),
                footer: Text("When category grouping is enabled, items are organized into Code & Web, Documents, and Data submenus.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            ) {
                Toggle("Group \"New File\" menu by category", isOn: $settingsManager.settings.groupByCategory)
                Toggle("Include \"Copy Path\" item", isOn: $settingsManager.settings.includeCopyPath)
                Toggle("Include \"Open in Terminal\" item", isOn: $settingsManager.settings.includeOpenTerminal)
            }

            Section(header: Text("System Integration")) {
                Toggle("Launch MacNewFile at login", isOn: $settingsManager.settings.launchAtLogin)

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
                    .buttonStyle(.bordered)
                }
            }

            Section(header: Text("About MacNewFile")) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("MacNewFile Enhanced")
                            .font(.headline)
                        Text("Version 3.0 • Native Quick Edit & File Creation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
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
