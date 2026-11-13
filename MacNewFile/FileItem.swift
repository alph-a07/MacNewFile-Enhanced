import Foundation

public struct FileItem: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var ext: String
    public var category: String
    public var enabledForNewFile: Bool
    public var enabledForQuickEditor: Bool
    public var customAppBundleIdentifier: String?
    public var customAppName: String?
    public var isCustom: Bool
    public var template: String
    public var icon: String
    public var creatorType: String // "standard", "docx", "xlsx", "pptx", "pages", "numbers", "key"

    public init(
        id: String,
        name: String,
        ext: String,
        category: String,
        enabledForNewFile: Bool = true,
        enabledForQuickEditor: Bool = true,
        customAppBundleIdentifier: String? = nil,
        customAppName: String? = nil,
        isCustom: Bool = false,
        template: String = "",
        icon: String = "doc",
        creatorType: String = "standard"
    ) {
        self.id = id
        self.name = name
        self.ext = ext.lowercased()
        self.category = category
        self.enabledForNewFile = enabledForNewFile
        self.enabledForQuickEditor = enabledForQuickEditor
        self.customAppBundleIdentifier = customAppBundleIdentifier
        self.customAppName = customAppName
        self.isCustom = isCustom
        self.template = template
        self.icon = icon
        self.creatorType = creatorType
    }

    // Custom decoder for backwards compatibility with previous "isEnabled" boolean
    enum CodingKeys: String, CodingKey {
        case id, name, ext, category, enabledForNewFile, enabledForQuickEditor, isEnabled
        case customAppBundleIdentifier, customAppName, isCustom, template, icon, creatorType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ext = (try container.decode(String.self, forKey: .ext)).lowercased()
        category = try container.decode(String.self, forKey: .category)

        let legacyIsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        enabledForNewFile = try container.decodeIfPresent(Bool.self, forKey: .enabledForNewFile) ?? legacyIsEnabled
        enabledForQuickEditor = try container.decodeIfPresent(Bool.self, forKey: .enabledForQuickEditor) ?? legacyIsEnabled

        customAppBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .customAppBundleIdentifier)
        customAppName = try container.decodeIfPresent(String.self, forKey: .customAppName)
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        template = try container.decodeIfPresent(String.self, forKey: .template) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "doc"
        creatorType = try container.decodeIfPresent(String.self, forKey: .creatorType) ?? "standard"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(ext, forKey: .ext)
        try container.encode(category, forKey: .category)
        try container.encode(enabledForNewFile, forKey: .enabledForNewFile)
        try container.encode(enabledForQuickEditor, forKey: .enabledForQuickEditor)
        try container.encode(customAppBundleIdentifier, forKey: .customAppBundleIdentifier)
        try container.encode(customAppName, forKey: .customAppName)
        try container.encode(isCustom, forKey: .isCustom)
        try container.encode(template, forKey: .template)
        try container.encode(icon, forKey: .icon)
        try container.encode(creatorType, forKey: .creatorType)
    }
}
