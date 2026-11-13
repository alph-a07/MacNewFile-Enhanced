import Foundation
import Combine

@objc(SettingsManager)
public class SettingsManager: NSObject, ObservableObject {
    @objc(sharedManager)
    public static let shared = SettingsManager()

    @Published public var settings: AppSettings

    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()

    private var settingsDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MacNewFile", isDirectory: true)
    }

    private var settingsFileURL: URL {
        return settingsDirectoryURL.appendingPathComponent("settings.json")
    }

    private override init() {
        self.settings = AppSettings.defaultSettings()
        super.init()
        loadSettings()

        // Auto-save whenever settings change
        $settings
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }

    @objc public func loadSettings() {
        do {
            if !fileManager.fileExists(atPath: settingsDirectoryURL.path) {
                try fileManager.createDirectory(at: settingsDirectoryURL, withIntermediateDirectories: true)
            }

            if fileManager.fileExists(atPath: settingsFileURL.path) {
                let data = try Data(contentsOf: settingsFileURL)
                let decoder = JSONDecoder()
                let loaded = try decoder.decode(AppSettings.self, from: data)
                self.settings = loaded
            } else {
                self.settings = AppSettings.defaultSettings()
                saveSettings()
            }
        } catch {
            NSLog("[MacNewFile] Failed to load settings: %@", error.localizedDescription)
            self.settings = AppSettings.defaultSettings()
        }
    }

    @objc public func saveSettings() {
        do {
            if !fileManager.fileExists(atPath: settingsDirectoryURL.path) {
                try fileManager.createDirectory(at: settingsDirectoryURL, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: settingsFileURL, options: .atomic)

            // Notify distributed listeners (such as Finder extension)
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name("com.louieyin.MacNewFile.SettingsChanged"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        } catch {
            NSLog("[MacNewFile] Failed to save settings: %@", error.localizedDescription)
        }
    }

    public func addCustomFileItem(name: String, ext: String, category: String = "Custom", template: String = "") {
        let cleanExt = ext.trimmingCharacters(in: CharacterSet(charactersIn: ". ")).lowercased()
        guard !cleanExt.isEmpty else { return }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(cleanExt.uppercased()) File" : name
        let uniqueId = "custom_\(cleanExt)_\(UUID().uuidString.prefix(6))"

        let newItem = FileItem(
            id: uniqueId,
            name: cleanName,
            ext: cleanExt,
            category: category.isEmpty ? "Custom" : category,
            isEnabled: true,
            isCustom: true,
            template: template,
            icon: "doc.badge.plus",
            creatorType: "standard"
        )

        settings.fileItems.append(newItem)
        saveSettings()
    }

    public func removeFileItem(id: String) {
        settings.fileItems.removeAll { $0.id == id }
        saveSettings()
    }

    public func toggleFileItem(id: String, enabled: Bool) {
        if let idx = settings.fileItems.firstIndex(where: { $0.id == id }) {
            settings.fileItems[idx].isEnabled = enabled
            saveSettings()
        }
    }

    public func setAllItems(enabled: Bool) {
        for idx in settings.fileItems.indices {
            settings.fileItems[idx].isEnabled = enabled
        }
        saveSettings()
    }

    public func resetToDefaults() {
        let defaults = AppSettings.defaultSettings()
        settings = defaults
        saveSettings()
    }
}
