# Changelog

All notable changes to **MacNewFile Enhanced** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.2.0] - 2026-11-14

### Highlights
MacNewFile Enhanced v3.2.0 is a massive product-ready release introducing the in-place **Quick Editor** (floating macOS Quick Look-style editor), independent file type controls, custom terminal app selection, full system font support, native opening/closing animations, and comprehensive Apple Human Interface Guidelines (HIG) visual refinements.

### Added
- **Instant In-Place Quick Editor (`⌥ Space`)**:
  - Floating Quick Look-style preview window that opens directly from selected file(s) in Finder.
  - Multi-tab support when multiple files are selected in Finder.
  - Dynamic responsiveness to Finder selection: arrow keys in Finder seamlessly switch the active Quick Editor document.
  - Automatic close when clicking empty space or selecting an incompatible/disabled file.
  - Repeating the shortcut toggles the editor open/closed, matching macOS Quick Look behavior.
  - Full keyboard shortcuts: `⌘S` (save), `Escape` / `⌘W` / `⌥ Space` (close), `⌘↵` (open in external app).
  - External application opener dropdown with auto-detection of compatible apps for the current file type.
  - In-place saving with immediate file updates and preservation of cursor position.
- **Custom Terminal Selection**:
  - Added dedicated **Terminal** settings tab allowing users to choose their preferred terminal emulator (Terminal.app, iTerm2, Alacritty, Kitty, Ghostty, Warp, WezTerm, Hyper, or custom app path).
  - Configurable custom command templates (e.g., `cd "%s"`).
- **Expanded Font Support**:
  - Quick Editor font picker now lists all available macOS system fonts (SF Mono, Menlo, Monaco, JetBrains Mono, Fira Code, Courier New, etc.) alongside customizable font sizing.
- **Fluid Opening/Closing Animations**:
  - Smooth spring zoom and fade animations anchored to the selected file's Finder icon location.
- **Expanded 34+ File Types Catalog**:
  - Code & Web: Python, JavaScript, TypeScript, HTML, CSS, JSON, YAML, Shell, Swift, C, C++, Rust, Go, SQL, XML, PHP, Ruby, Java, Kotlin, Dart.
  - Documents & Notes: Plain Text, Markdown, Rich Text, Word, Excel, PowerPoint, Pages, Numbers, Keynote.
  - Data & Config: CSV, TSV, Env (`.env`), INI, TOML, Log (`.log`), Dotfiles (`.gitignore`, `.zshrc`).
- **Independent Enablement Architecture**:
  - File types can now be independently toggled for "New File" context menu and "Quick Editor" preview.
- **Quality Assurance & Open Source Infrastructure**:
  - 180-point automated test sweep suite (`tests/run_full_test_sweep.swift`) covering hotkeys, extensions, animations, terminal commands, and menu generation.
  - Automated CI/CD workflows (`ci.yml` and `release.yml`) for automated building, testing, and GitHub release packaging.
  - Comprehensive Open Source Project Checklist (`CHECKLIST.md`).

### Changed
- **Finder Right-Click Menu Enhancements**:
  - Dynamic rasterization of template icons with light/dark appearance awareness (`NSAppearance.currentDrawingAppearance`).
  - Native SF Symbols styling and consistent menu iconography.
  - Reliable cross-process target folder URL resolution with AppleScript fallback.
- **Modern Apple Design Overhaul**:
  - Redesigned Settings window with standard segmented toolbar (File Types, Quick Editor, Terminal, General).
  - Balanced typography, proper alignment, and refined visual hierarchy.
  - Cleaned up menubar status item with native Apple HIG styling.

### Fixed
- Fixed icon tinting issue where menu icons appeared inverted or clipped in dark mode.
- Fixed right-click "New File" not capturing Finder's active working directory.
- Fixed Option+Space Quick Editor crashing when pressing shortcut on empty desktop.
- Fixed dotfiles (like `.gitignore` and `.zshrc`) failing extension resolution in Quick Editor.
- Fixed window crushing bug during rapid open/close cycles.

---

## [3.1.1] - 2026-04-14

### Added
- Italian localization support.
- CLI-based automated build script (`scripts/build.sh`) allowing compilation without full Xcode GUI.

### Fixed
- Improved background process cleanup and menu responsiveness.

---

## [3.0.0] - 2025-10-10

### Added
- Initial SwiftUI Settings panel.
- Dynamic file type toggle options.
- Finder contextual menu integration with FinderSync framework.
