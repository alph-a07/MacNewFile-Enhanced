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

    private var activeCount: Int {
        settingsManager.settings.fileItems.filter { $0.isEnabled }.count
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
                    Label("Quick Editor", systemImage: "pencil.and.outline")
                }
                .tag(1)

            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(2)
        }
        .frame(minWidth: 640, idealWidth: 700, minHeight: 490, idealHeight: 540)
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            addCustomTypeSheet
        }
    }

    // MARK: - File Types Tab
    private var fileTypesTab: some View {
        VStack(spacing: 0) {
            // Top Bar
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finder Context Menu File Types")
                            .font(.headline)
                        Text("\(activeCount) of \(settingsManager.settings.fileItems.count) file types enabled in right-click menu")
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

                // Search & Category Filter
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search file types or extension...", text: $viewModel.searchText)
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

                // Bulk controls
                HStack {
                    Button("Enable All") {
                        settingsManager.setAllItems(enabled: true)
                    }
                    .buttonStyle(.link)

                    Text("•").foregroundColor(.secondary)

                    Button("Disable All") {
                        settingsManager.setAllItems(enabled: false)
                    }
                    .buttonStyle(.link)

                    Text("•").foregroundColor(.secondary)

                    Button("Reset to Defaults") {
                        settingsManager.resetToDefaults()
                    }
                    .buttonStyle(.link)

                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // List of File Types
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
                .foregroundColor(item.isEnabled ? .accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(".\(item.ext)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.18))
                        .cornerRadius(4)
                }

                HStack(spacing: 6) {
                    Text(item.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)

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
                .padding(.trailing, 8)
            }

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { newValue in
                    settingsManager.toggleFileItem(id: item.id, enabled: newValue)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Quick Editor Tab
    private var quickEditorTab: some View {
        Form {
            Section(header: Text("Shortcut & Activation").font(.headline)) {
                Picker("Global Shortcut:", selection: $settingsManager.settings.quickEditorShortcut) {
                    Text("Option + Space (⌥ Space)").tag("Option+Space")
                    Text("Command + Shift + E (⌘⇧E)").tag("Cmd+Shift+E")
                    Text("Control + Option + N (⌃⌥N)").tag("Ctrl+Opt+N")
                    Text("Command + Option + E (⌘⌥E)").tag("Cmd+Opt+E")
                }
                .pickerStyle(.menu)

                Text("Select a file in Finder and press this shortcut to instantly preview and edit it without opening a heavy IDE.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Show \"Quick Edit\" in Finder context menu", isOn: $settingsManager.settings.showQuickEditInMenu)
            }

            Section(header: Text("Editor Typography & Appearance").font(.headline)) {
                Picker("Font Family:", selection: $settingsManager.settings.quickEditorFontFamily) {
                    Text("SF Mono").tag("SF Mono")
                    Text("Menlo").tag("Menlo")
                    Text("Courier New").tag("Courier New")
                }

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

                Toggle("Show Line Numbers", isOn: $settingsManager.settings.showLineNumbers)
                Toggle("Soft Word Wrap", isOn: $settingsManager.settings.wordWrap)
            }

            Section(header: Text("Live Editor Preview").font(.headline)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(Color.red.opacity(0.8)).frame(width: 10, height: 10)
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 10, height: 10)
                        Circle().fill(Color.green.opacity(0.8)).frame(width: 10, height: 10)
                        Spacer()
                        Text("preview.py")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.windowBackgroundColor))

                    HStack(alignment: .top, spacing: 8) {
                        if settingsManager.settings.showLineNumbers {
                            VStack(alignment: .trailing, spacing: 2) {
                                ForEach(1...5, id: \.self) { num in
                                    Text("\(num)")
                                        .font(.system(size: CGFloat(settingsManager.settings.quickEditorFontSize) - 1, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 25)
                            Divider()
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("def hello_world():")
                            Text("    message = \"Quick editing in Finder!\"")
                            Text("    print(message)")
                            Text("    return True")
                            Text("hello_world()")
                        }
                        .font(.system(size: CGFloat(settingsManager.settings.quickEditorFontSize), design: .monospaced))
                        .foregroundColor(settingsManager.settings.quickEditorTheme == "dark" ? .white : .primary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(settingsManager.settings.quickEditorTheme == "dark" ? Color(red: 0.12, green: 0.12, blue: 0.13) : Color(NSColor.textBackgroundColor))
                }
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(20)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section(header: Text("Finder Integration").font(.headline)) {
                Toggle("Group \"New File\" Menu by Category", isOn: $settingsManager.settings.groupByCategory)
                Text("When enabled, shows submenus like 'Code & Web', 'Documents & Notes'. When disabled, shows all active types in a clean flat list.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Include \"Copy Path\" item", isOn: $settingsManager.settings.includeCopyPath)
                Toggle("Include \"Open New Terminal\" item", isOn: $settingsManager.settings.includeOpenTerminal)
            }

            Section(header: Text("System & Startup").font(.headline)) {
                Toggle("Launch MacNewFile at Login", isOn: $settingsManager.settings.launchAtLogin)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finder Extension Status")
                            .font(.system(size: 13, weight: .medium))
                        Text("If the right-click menu does not appear in Finder, click below to re-register.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Refresh Extension") {
                        reRegisterExtension()
                    }
                }
            }

            Section(header: Text("About MacNewFile Enhanced").font(.headline)) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.square.fill.on.square.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MacNewFile Enhanced Fork")
                            .font(.system(size: 14, weight: .bold))
                        Text("Version 3.2.0 • On-Demand File Types & Quick Editor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
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
                TextField("Display Name (e.g. Vue Single File Component):", text: $viewModel.newName)

                Picker("Category:", selection: $viewModel.newCategory) {
                    Text("Code & Web").tag("Code & Web")
                    Text("Documents & Notes").tag("Documents & Notes")
                    Text("Data & Config").tag("Data & Config")
                    Text("Custom").tag("Custom")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Boilerplate / Template Content (optional):")
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
