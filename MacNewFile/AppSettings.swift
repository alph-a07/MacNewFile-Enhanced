import Foundation

public struct AppSettings: Codable, Equatable {
    public var version: Int = 3
    public var fileItems: [FileItem] = []
    public var groupByCategory: Bool = false
    public var showQuickEditInMenu: Bool = true
    public var quickEditorShortcut: String = "Option+Space"
    public var quickEditorFontSize: Double = 13.0
    public var quickEditorFontFamily: String = "SF Mono"
    public var quickEditorTheme: String = "system" // "system", "dark", "light"
    public var showLineNumbers: Bool = true
    public var wordWrap: Bool = true
    public var enableQuickLookAnimation: Bool = true
    public var includeCopyPath: Bool = true
    public var includeOpenTerminal: Bool = true
    public var terminalApp: String = "Terminal" // "Terminal", "iTerm", "Warp", "Ghostty", "Alacritty", "Kitty", "Custom"
    public var terminalAppCustomPath: String? = nil
    public var launchAtLogin: Bool = true

    public static func defaultSettings() -> AppSettings {
        var settings = AppSettings()
        settings.fileItems = defaultFileItems()
        return settings
    }

    public static func defaultFileItems() -> [FileItem] {
        return [
            // Code & Web
            FileItem(
                id: "py",
                name: "Python Script",
                ext: "py",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "#!/usr/bin/env python3\n\ndef main():\n    print(\"Hello, World!\")\n\nif __name__ == '__main__':\n    main()\n",
                icon: "chevron.left.forwardslash.chevron.right"
            ),
            FileItem(
                id: "js",
                name: "JavaScript File",
                ext: "js",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "\"use strict\";\n\nconsole.log(\"Hello, World!\");\n",
                icon: "chevron.left.forwardslash.chevron.right"
            ),
            FileItem(
                id: "ts",
                name: "TypeScript File",
                ext: "ts",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "export {};\n\nconsole.log(\"Hello TypeScript!\");\n",
                icon: "chevron.left.forwardslash.chevron.right"
            ),
            FileItem(
                id: "html",
                name: "HTML Document",
                ext: "html",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>Document</title>\n</head>\n<body>\n  <h1>Hello, World!</h1>\n</body>\n</html>\n",
                icon: "globe"
            ),
            FileItem(
                id: "css",
                name: "CSS Stylesheet",
                ext: "css",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "/* Styles */\n* {\n  box-sizing: border-box;\n  margin: 0;\n  padding: 0;\n}\n",
                icon: "paintbrush"
            ),
            FileItem(
                id: "json",
                name: "JSON File",
                ext: "json",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "{\n  \n}\n",
                icon: "curlybraces"
            ),
            FileItem(
                id: "yaml",
                name: "YAML File",
                ext: "yaml",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "version: \"1.0\"\n",
                icon: "list.bullet.rectangle"
            ),
            FileItem(
                id: "sh",
                name: "Shell Script",
                ext: "sh",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "#!/usr/bin/env bash\nset -euo pipefail\n\necho \"Hello from Bash!\"\n",
                icon: "terminal"
            ),
            FileItem(
                id: "swift",
                name: "Swift Source",
                ext: "swift",
                category: "Code & Web",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "import Foundation\n\nprint(\"Hello, Swift!\")\n",
                icon: "swift"
            ),
            FileItem(
                id: "c",
                name: "C Source",
                ext: "c",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "#include <stdio.h>\n\nint main(void) {\n    printf(\"Hello, World!\\n\");\n    return 0;\n}\n",
                icon: "c.circle"
            ),
            FileItem(
                id: "cpp",
                name: "C++ Source",
                ext: "cpp",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, World!\" << std::endl;\n    return 0;\n}\n",
                icon: "plus.slash.minus"
            ),
            FileItem(
                id: "h",
                name: "C/C++ Header",
                ext: "h",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "#pragma once\n",
                icon: "doc.text"
            ),
            FileItem(
                id: "rs",
                name: "Rust Source",
                ext: "rs",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "fn main() {\n    println!(\"Hello, World!\");\n}\n",
                icon: "gearshape"
            ),
            FileItem(
                id: "go",
                name: "Go Source",
                ext: "go",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "package main\n\nimport \"fmt\"\n\nfunc main() {\n    fmt.Println(\"Hello, World!\")\n}\n",
                icon: "arrow.triangle.2.circlepath"
            ),
            FileItem(
                id: "sql",
                name: "SQL Script",
                ext: "sql",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "-- SQL Query\nSELECT 1;\n",
                icon: "cylinder"
            ),
            FileItem(
                id: "xml",
                name: "XML Document",
                ext: "xml",
                category: "Code & Web",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>\n</root>\n",
                icon: "chevron.left.forwardslash.chevron.right"
            ),

            // Documents & Notes
            FileItem(
                id: "txt",
                name: "Text File",
                ext: "txt",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "",
                icon: "doc.text"
            ),
            FileItem(
                id: "md",
                name: "Markdown Document",
                ext: "md",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "# Title\n\n",
                icon: "doc.plaintext"
            ),
            FileItem(
                id: "rtf",
                name: "Rich Text Document",
                ext: "rtf",
                category: "Documents & Notes",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Arial;}}\\f0\\fs24 \\par}",
                icon: "doc.richtext"
            ),
            FileItem(
                id: "docx",
                name: "Microsoft Word Document",
                ext: "docx",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "doc.fill",
                creatorType: "docx"
            ),
            FileItem(
                id: "xlsx",
                name: "Microsoft Excel Spreadsheet",
                ext: "xlsx",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "tablecells",
                creatorType: "xlsx"
            ),
            FileItem(
                id: "pptx",
                name: "Microsoft PowerPoint Presentation",
                ext: "pptx",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "play.rectangle",
                creatorType: "pptx"
            ),
            FileItem(
                id: "pages",
                name: "Apple Pages Document",
                ext: "pages",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "doc.text.fill",
                creatorType: "pages"
            ),
            FileItem(
                id: "numbers",
                name: "Apple Numbers Spreadsheet",
                ext: "numbers",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "chart.bar",
                creatorType: "numbers"
            ),
            FileItem(
                id: "key",
                name: "Apple Keynote Presentation",
                ext: "key",
                category: "Documents & Notes",
                enabledForNewFile: true,
                enabledForQuickEditor: false,
                template: "",
                icon: "tv",
                creatorType: "key"
            ),

            // Data & Config
            FileItem(
                id: "csv",
                name: "CSV Spreadsheet",
                ext: "csv",
                category: "Data & Config",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "Column1,Column2,Column3\n",
                icon: "tablecells"
            ),
            FileItem(
                id: "tsv",
                name: "TSV File",
                ext: "tsv",
                category: "Data & Config",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "Col1\tCol2\tCol3\n",
                icon: "tablecells"
            ),
            FileItem(
                id: "env",
                name: "Environment File",
                ext: "env",
                category: "Data & Config",
                enabledForNewFile: true,
                enabledForQuickEditor: true,
                template: "# Environment Variables\nNODE_ENV=development\nPORT=3000\n",
                icon: "gear"
            ),
            FileItem(
                id: "ini",
                name: "INI Configuration",
                ext: "ini",
                category: "Data & Config",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "[General]\nkey=value\n",
                icon: "slider.horizontal.3"
            ),
            FileItem(
                id: "toml",
                name: "TOML Configuration",
                ext: "toml",
                category: "Data & Config",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "[general]\nkey = \"value\"\n",
                icon: "slider.horizontal.3"
            ),
            FileItem(
                id: "log",
                name: "Log File",
                ext: "log",
                category: "Data & Config",
                enabledForNewFile: false,
                enabledForQuickEditor: true,
                template: "",
                icon: "scroll"
            )
        ]
    }
}
