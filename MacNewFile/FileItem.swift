import Foundation

public struct FileItem: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var ext: String
    public var category: String
    public var isEnabled: Bool
    public var isCustom: Bool
    public var template: String
    public var icon: String
    public var creatorType: String // "standard", "docx", "xlsx", "pptx", "pages", "numbers", "key"

    public init(
        id: String,
        name: String,
        ext: String,
        category: String,
        isEnabled: Bool = true,
        isCustom: Bool = false,
        template: String = "",
        icon: String = "doc",
        creatorType: String = "standard"
    ) {
        self.id = id
        self.name = name
        self.ext = ext
        self.category = category
        self.isEnabled = isEnabled
        self.isCustom = isCustom
        self.template = template
        self.icon = icon
        self.creatorType = creatorType
    }
}
