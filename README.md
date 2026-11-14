<div align="center">

<img src="./MacNewFile/Assets.xcassets/AppIcon.appiconset/add (1) (1)-modified.png" width="108" height="108" alt="MacNewFile Logo">

# MacNewFile Enhanced

**The missing right-click file creator and in-place Quick Editor for macOS Finder.**

[![CI](https://github.com/alph-a07/MacNewFile-Enhanced/actions/workflows/ci.yml/badge.svg)](https://github.com/alph-a07/MacNewFile-Enhanced/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/alph-a07/MacNewFile-Enhanced?color=2ea44f&label=Release)](https://github.com/alph-a07/MacNewFile-Enhanced/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/alph-a07/MacNewFile-Enhanced/blob/main/LICENSE)
[![macOS Compatibility](https://img.shields.io/badge/macOS-11.0%20to%2015.x%2B-A2AAAD?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-success)](#system-requirements)
[![FOSS](https://img.shields.io/badge/FOSS-100%25%20Free%20%26%20Open%20Source-ff69b4)](#my-promise-as-an-open-source-developer)

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="#why-macnewfile-enhanced">Why MacNewFile?</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#faq--troubleshooting">FAQ</a> •
  <a href="./CHECKLIST.md">Checklist</a>
</p>

</div>

---

## Overview

One of the most jarring transitions when moving to macOS is that **Finder does not allow you to right-click to create a new file**, unlike Windows, Linux GNOME, or KDE. Furthermore, while macOS **Quick Look (`Space`)** is great for reading, you cannot make quick edits to scripts, dotfiles, or markdown documents without firing up a heavy IDE.

**MacNewFile Enhanced** bridges both gaps natively:
1. **Right-Click "New File" Menu**: Create any of 34+ file types or your own custom extensions directly in any Finder directory or the Desktop.
2. **Instant In-Place Quick Editor (`⌥ Space`)**: A floating, editable Quick Look-style editor that opens right over Finder with syntax themes, line numbers, system fonts, and external app launching.

---

## Why MacNewFile Enhanced?

| Feature | Default macOS Finder | macOS Quick Look (`Space`) | Windows File Explorer | **MacNewFile Enhanced** |
| :--- | :---: | :---: | :---: | :---: |
| **Right-Click New File** | ❌ (Folders only) | ❌ | ✅ (Basic) | **✅ 34+ types + Custom** |
| **In-Place File Editing** | ❌ | ❌ (View only) | ❌ | **✅ Full In-Place Editor** |
| **Finder Selection Sync** | ❌ | ✅ | ❌ | **✅ Dynamic Finder Sync** |
| **Multi-File Tabbed Preview** | ❌ | ❌ | ❌ | **✅ Tabbed Editor (`⌥ Space`)** |
| **Custom Terminal Integration**| ❌ (Terminal only) | ❌ | ❌ | **✅ 8+ Terminal Emulators** |
| **Open Source & Extensible** | ❌ | ❌ | ❌ | **✅ 100% GPL-3.0 FOSS** |

---

## Features

### 1. Right-Click Context Menu ("New File")
- **34+ Built-in File Types**:
  - **Code & Web**: Python (`.py`), JavaScript (`.js`), TypeScript (`.ts`), HTML (`.html`), CSS (`.css`), JSON (`.json`), YAML (`.yaml`), Shell (`.sh`), Swift (`.swift`), C (`.c`), C++ (`.cpp`), Rust (`.rs`), Go (`.go`), SQL (`.sql`), XML (`.xml`).
  - **Documents & Notes**: Plain Text (`.txt`), Markdown (`.md`), Rich Text (`.rtf`), Microsoft Word (`.docx`), Excel (`.xlsx`), PowerPoint (`.pptx`), Pages (`.pages`), Numbers (`.numbers`), Keynote (`.key`).
  - **Data & Config**: CSV (`.csv`), TSV (`.tsv`), Environment (`.env`), INI (`.ini`), TOML (`.toml`), Log (`.log`), Dotfiles (`.gitignore`, `.zshrc`).
- **Custom File Types**: Add any extension (e.g. `.svelte`, `.vue`, `.proto`, `.graphql`) with custom display names, categories, and starter boilerplate templates.
- **Independent Enablement**: Toggle types on/off for the "New File" menu independently from the Quick Editor.
- **Native Apple Appearance**: Dynamic template icons that automatically rasterize with light and dark mode awareness (`NSAppearance`).

### 2. Instant In-Place Quick Editor (`⌥ Space`)
- **Quick Look, but Editable**: Select any file in Finder and hit `⌥ Space` to open a floating, translucent editor pane directly over your file.
- **Reactive Finder Selection**: Navigating with arrow keys in Finder automatically updates the editor preview in real time.
- **Multi-Tab Workspace**: Hit `⌥ Space` on a multi-file selection to edit all eligible files in a unified, tabbed window.
- **Auto-Close on Deselection**: Clicking empty space in Finder or selecting an unsupported file gracefully closes the editor.
- **Quick Save & Launch**: Save instantly with `⌘S`. Press `⌘↵` to open the file in external editors (VS Code, Cursor, Zed, Sublime, or Xcode) with compatible app auto-detection.
- **Typography & Themes**: Choose any installed system font (SF Mono, Menlo, Monaco, JetBrains Mono, Fira Code), configure font size, toggle word wrap, line numbers gutter, and switch between System, VS Code Dark Modern, and Light themes.

### 3. Custom Terminal App Launcher
- Select your preferred terminal emulator from Settings:
  - **Terminal.app**, **iTerm2**, **Alacritty**, **Kitty**, **Ghostty**, **Warp**, **WezTerm**, **Hyper**, or a custom app binary path.
- Configurable launch command templates (default: `cd "%s"`).

### 4. Apple Human Interface Guidelines (HIG) Design
- Redesigned macOS Settings panel with native segmented controls.
- Sub-millisecond execution with zero background CPU/memory footprint.

---

## Keyboard Shortcuts

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| `⌥ Space` | Finder (file selected) | Open / Close Quick Editor (toggle) |
| `⌘S` | Quick Editor | Save changes to file in-place |
| `Escape` or `⌘W` | Quick Editor | Close Quick Editor |
| `⌘↵` | Quick Editor | Open current file in selected external editor |
| `↑` / `↓` / `←` / `→` | Finder (editor open) | Dynamically switch preview to newly selected file |
| `⌘,` | Menu Bar App | Open Settings window |

---

## System Requirements

- **Operating System**: macOS 11.0 (Big Sur), macOS 12 (Monterey), macOS 13 (Ventura), macOS 14 (Sonoma), or macOS 15+ (Sequoia)
- **Architecture**: Universal binary supporting both **Apple Silicon** (`arm64`: M1/M2/M3/M4) and **Intel** (`x86_64`)
- **Finder Sync Extension**: Supported on all local volumes and folders (APFS, Mac OS Extended, external drives). Note: iCloud Drive directory root restricts FinderSync injection per Apple macOS policy.

---

## Installation

### Option 1: Direct Release Download (Recommended)

1. Download the latest `MacNewFile.zip` from the **[GitHub Releases](https://github.com/alph-a07/MacNewFile-Enhanced/releases)** page.
2. Unzip `MacNewFile.zip` and move `MacNewFile.app` to your `/Applications` folder.
3. Open Terminal and remove the quarantine attribute (since open-source apps are distributed outside the Mac App Store):
   ```bash
   xattr -dr com.apple.quarantine /Applications/MacNewFile.app
   ```
4. Launch `MacNewFile.app`.
5. Enable the extension in macOS Settings:
   - **macOS 13+**: `System Settings` → `General` → `Login Items & Extensions` → `File Providers / Finder Extensions` → Enable **MacNewFile**.
   - **macOS 12 and earlier**: `System Preferences` → `Extensions` → `Finder Extensions` → Check **MacNewFile**.

### Option 2: Build from Source (Fast CLI Build)

No full Xcode IDE installation is required! You only need the macOS Command Line Tools:

```bash
# 1. Clone the repository
git clone https://github.com/alph-a07/MacNewFile-Enhanced.git
cd MacNewFile-Enhanced

# 2. Run automated build script
chmod +x scripts/build.sh
./scripts/build.sh

# 3. Verify tests
swift tests/run_full_test_sweep.swift
```

The script compiles the Swift and Objective-C Mach-O binaries, codesigns with entitlements, registers the extension with `pluginkit` and `LaunchServices`, and installs `MacNewFile.app` into `/Applications`.

### Option 3: Build in Xcode

1. Open `MacNewFile.xcodeproj` in Xcode 14+.
2. Select target `MacNewFile` and build (`⌘B`) or run (`⌘R`).

---

## Quality Assurance & Automated Tests

MacNewFile Enhanced comes with a self-contained 180-point automated test sweep that validates:
- Finder context menu generation and URL resolution.
- Hotkey configuration and custom shortcut parsing.
- Extension resolution across all 34+ file types, custom extensions, and dotfiles (`.gitignore`, `.zshrc`).
- In-place Quick Editor document state, multi-tab switching, and spring animation parameters.
- Terminal commands for 8+ terminal emulators.

To run the test suite:
```bash
swift tests/run_full_test_sweep.swift
```
Expected output:
```text
=== ALL TEST SUITES PASSED (180/180) ===
```

---

## Architecture

```
MacNewFile-Enhanced/
├── MacNewFile/                     # Main Application (Menu bar & Quick Editor)
│   ├── AppDelegate.m               # App lifecycle, cross-process creation helper
│   ├── SettingsView.swift          # Modern SwiftUI settings interface
│   ├── QuickEditorWindowController.swift # Floating Quick Look editor panel
│   ├── LineNumberGutterView.swift  # Monospace editor gutter & line numbers
│   ├── GlobalHotkeyManager.swift   # Carbon global hotkey monitor & Finder polling
│   ├── SettingsManager.swift       # Shared App Group user defaults persistence
│   └── FileItem.swift              # Built-in catalog of 34+ file types
│
├── MacNewFileFinderExtension/      # Sandboxed FinderSync Plugin
│   ├── FinderSync.m                # Finder context menu, dynamic icons, path capture
│   └── Blank.*                     # Blank office document templates
│
├── scripts/
│   └── build.sh                    # Standalone CLI compilation & codesign script
│
├── tests/
│   └── run_full_test_sweep.swift   # 180-point automated test sweep suite
│
└── .github/
    └── workflows/                  # CI/CD: Automated build, test, and release packaging
```

---

## FAQ & Troubleshooting

<details>
<summary><strong>The "New File" option does not appear when right-clicking in Finder.</strong></summary>

1. Ensure the Finder extension is enabled:
   - Go to `System Settings` → `General` → `Login Items & Extensions` → `Finder Extensions` and ensure **MacNewFile** is checked.
2. Restart Finder to reload extensions:
   ```bash
   killall Finder
   ```
3. Make sure `MacNewFile.app` is running in your menu bar (look for the `+` icon).
</details>

<details>
<summary><strong>Option + Space does not open the Quick Editor.</strong></summary>

1. Ensure `MacNewFile.app` has **Accessibility** permissions:
   - `System Settings` → `Privacy & Security` → `Accessibility` → Enable **MacNewFile**.
2. Make sure the file you selected in Finder has its file type enabled under the **Quick Editor** column in MacNewFile Settings (`⌘,`).
3. You can customize the shortcut in Settings (e.g. `⌘⇧E` or `⌘⌥E`) if `⌥ Space` conflicts with another utility (e.g. Raycast or Alfred).
</details>

<details>
<summary><strong>Why does macOS display a security warning when opening for the first time?</strong></summary>

Apple requires developers to pay an annual \$99 USD developer subscription to obtain an official Notarization ticket. As a 100% free and open-source utility, MacNewFile is signed with an ad-hoc certificate. Running:
```bash
xattr -dr com.apple.quarantine /Applications/MacNewFile.app
```
removes the quarantine flag and allows the app to run natively.
</details>

---

## Contributing

We welcome contributions from everyone! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) before submitting pull requests.

Check our progress against the [Open Source Project Checklist](./CHECKLIST.md).

---

## License

This project is licensed under the **GNU General Public License v3.0** (`GPL-3.0`). See the [LICENSE](./LICENSE) file for complete details.
