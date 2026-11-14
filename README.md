<div align="center">

<img src="./docs/assets/app-icon.png" width="96" height="96" alt="MacNewFile Icon">

# MacNewFile

**Right-click file creation and in-place Quick Editor for macOS Finder.**

[![CI](https://github.com/alph-a07/MacNewFile-Enhanced/actions/workflows/ci.yml/badge.svg)](https://github.com/alph-a07/MacNewFile-Enhanced/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/alph-a07/MacNewFile-Enhanced?color=0071e3&label=Release)](https://github.com/alph-a07/MacNewFile-Enhanced/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-gray.svg)](https://github.com/alph-a07/MacNewFile-Enhanced/blob/main/LICENSE)
[![macOS Compatibility](https://img.shields.io/badge/macOS-11.0%20to%2015.x%2B-gray?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-gray)](#system-requirements)

<p align="center">
  <a href="https://alph-a07.github.io/MacNewFile-Enhanced/"><strong>Website &amp; Live Showcase</strong></a> •
  <a href="#quickstart">Quickstart</a> •
  <a href="#core-features">Features</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#faq--troubleshooting">FAQ</a>
</p>

</div>

---

## Overview

Unlike Windows Explorer or Linux desktop environments, macOS Finder has never provided a native contextual menu option to create new files in arbitrary directories. Furthermore, while macOS Quick Look (`Space`) offers convenient read-only previews, quick edits to code snippets, dotfiles, or markdown notes traditionally require launching a heavy IDE.

**MacNewFile** bridges both gaps natively with zero background daemons and zero Electron overhead:

1. **Right-Click "New File" Menu**: Create any of 34+ curated file types (or your own custom extensions) directly in any Finder directory or the Desktop.
2. **Instant In-Place Quick Editor (`⌥ Space`)**: A floating, editable Quick Look-style editor anchored over Finder with real-time arrow navigation sync, multi-tab support, and external IDE integration.

---

## Quickstart

Follow these three steps to get MacNewFile running on your Mac:

```mermaid
flowchart LR
    A["1. Install App<br>(Homebrew or .zip)"] --> B["2. Enable Extension<br>(Finder Extensions)"]
    B --> C["3. Grant Accessibility<br>(⌥ Space Hotkey)"]
    C --> D["Ready to Use<br>(Right-click in Finder)"]
```

1. **Install MacNewFile**:
   ```bash
   brew install --cask macnewfile
   ```
   *(Or download `MacNewFile.zip` from [Releases](https://github.com/alph-a07/MacNewFile-Enhanced/releases/latest) and move to `/Applications`)*.
2. **Enable Finder Extension**:
   - Open **System Settings → General → Login Items & Extensions → Finder Extensions**.
   - Check **MacNewFile**.
   - Run `killall Finder` in Terminal if the menu does not appear immediately.
3. **Grant Accessibility Permissions** (for Quick Editor):
   - Open **System Settings → Privacy & Security → Accessibility**.
   - Enable **MacNewFile** so the global `⌥ Space` shortcut can detect active Finder selections.

---

## Feature Comparison

| Capability | macOS Finder | Quick Look (`Space`) | Windows Explorer | **MacNewFile** |
| :--- | :---: | :---: | :---: | :---: |
| **Right-Click New File** | — (Folders only) | — | Basic list | **34+ Formats + Custom** |
| **In-Place File Editing** | — | — (Read-only) | — | **Full In-Place Editor (`⌥ Space`)** |
| **Finder Selection Sync** | — | Arrow tracking | — | **Live Arrow Selection Sync** |
| **Multi-File Tabbed Preview** | — | — | — | **Multi-Tab Workspace** |
| **Terminal Integration** | — (Terminal.app only) | — | — | **8+ Terminal Emulators** |
| **Open Source** | Proprietary | Proprietary | Proprietary | **100% Free & Open Source (GPL-3.0)** |

---

## Core Features

### 1. Right-Click Context Menu ("New File")
- **34+ Built-in Formats**:
  - **Code & Web**: Python (`.py`), JavaScript (`.js`), TypeScript (`.ts`), HTML (`.html`), CSS (`.css`), JSON (`.json`), YAML (`.yaml`), Shell (`.sh`), Swift (`.swift`), C (`.c`), C++ (`.cpp`), Rust (`.rs`), Go (`.go`), SQL (`.sql`), XML (`.xml`).
  - **Documents & Notes**: Plain Text (`.txt`), Markdown (`.md`), Rich Text (`.rtf`), Word (`.docx`), Excel (`.xlsx`), PowerPoint (`.pptx`), Pages (`.pages`), Numbers (`.numbers`), Keynote (`.key`).
  - **Data & Config**: CSV (`.csv`), TSV (`.tsv`), Environment (`.env`), INI (`.ini`), TOML (`.toml`), Log (`.log`), Dotfiles (`.gitignore`, `.zshrc`).
- **Custom Formats**: Register any custom extension (e.g. `.svelte`, `.vue`, `.proto`) with starter templates.
- **Dynamic Appearance**: Menu icons rasterize automatically to match macOS Light and Dark appearance.
- **Instant Inline Rename**: Automatically focuses Finder's rename field on the newly created file.

### 2. Instant In-Place Quick Editor (`⌥ Space`)
- **Editable Quick Look**: Select any file in Finder and press `⌥ Space` to open an in-place editor window.
- **Reactive Finder Navigation**: Use arrow keys in Finder to dynamically switch the editor preview to adjacent files.
- **Multi-Document Tabs**: Selecting multiple files in Finder opens all eligible documents in a clean tabbed window.
- **One-Key IDE Launch**: Save changes with `⌘S`, or press `⌘↵` to open the file in your primary editor (VS Code, Cursor, Zed, Sublime, or Xcode).
- **Custom Typography**: Select any installed macOS system font (SF Mono, Menlo, JetBrains Mono, Fira Code), customize font size, toggle line numbers, and switch between System, Dark Modern, and Light themes.

### 3. Terminal Emulator Integration
- Right-click "Open in Terminal" in any Finder folder to launch directly into your favorite emulator:
  - **Ghostty**, **iTerm2**, **Terminal.app**, **Warp**, **Alacritty**, **kitty**, **WezTerm**, or a custom app binary path.
- Configurable command templates (default: `cd "%s"`).

### 4. Independent File Type Controls
- Configure format availability with granular controls: enable a file format for the "New File" context menu without enabling it in the Quick Editor, and vice versa.

---

## Keyboard Shortcuts

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| `⌥ Space` | Finder (file selected) | Open or close Quick Editor (toggle) |
| `⌘S` | Quick Editor | Save changes to file in-place |
| `Escape` or `⌘W` | Quick Editor | Close Quick Editor |
| `⌘↵` | Quick Editor | Open active file in external editor (VS Code, Cursor, Zed) |
| `↑` / `↓` / `←` / `→` | Finder (editor open) | Dynamically switch preview to newly selected file |
| `⌘,` | MacNewFile Menu Bar | Open Settings window |

---

## System Requirements

- **Operating System**: macOS 11.0 (Big Sur) through macOS 15+ (Sequoia).
- **Architecture**: Universal binary supporting both **Apple Silicon** (`arm64`: M1/M2/M3/M4) and **Intel** (`x86_64`).
- **Volume Support**: Local APFS, Mac OS Extended, and external volumes. *(Note: Apple system policy restricts third-party FinderSync extensions at the root of iCloud Drive; subfolders inside iCloud Drive are supported).*

---

## Installation

### Method 1: Homebrew (Recommended)

```bash
brew install --cask macnewfile
```

### Method 2: Direct Release Download

1. Download `MacNewFile.zip` from **[GitHub Releases](https://github.com/alph-a07/MacNewFile-Enhanced/releases/latest)**.
2. Unzip and move `MacNewFile.app` to `/Applications`.
3. Open Terminal and remove the quarantine attribute (required because open-source releases are distributed outside the Mac App Store):
   ```bash
   xattr -dr com.apple.quarantine /Applications/MacNewFile.app
   ```
4. Launch `MacNewFile.app` and complete the 3-step setup above.

### Method 3: Compile from Source (CLI Build)

No full Xcode installation required—only Apple Command Line Tools:

```bash
# 1. Clone the repository
git clone https://github.com/alph-a07/MacNewFile-Enhanced.git
cd MacNewFile-Enhanced

# 2. Build binaries and package app bundle
chmod +x scripts/build.sh
./scripts/build.sh

# 3. Verify automated test sweep
swift tests/run_full_test_sweep.swift
```

---

## Automated Verification & Testing

MacNewFile includes a self-contained 180-test verification suite that exercises hotkeys, extension resolution, multi-tab states, spring animations, and terminal command generation:

```bash
swift tests/run_full_test_sweep.swift
```

Expected output:
```text
==========================================
TEST SUMMARY: 180 PASSED, 0 FAILED
==========================================
```

---

## Architecture

```text
MacNewFile/
├── MacNewFile/                     # Main Application (Menu bar & Quick Editor)
│   ├── AppDelegate.m               # Lifecycle, cross-process creation helper
│   ├── SettingsView.swift          # Modern SwiftUI settings interface
│   ├── QuickEditorWindowController.swift # Floating Quick Look editor panel
│   ├── LineNumberGutterView.swift  # Monospace gutter & line numbers
│   ├── GlobalHotkeyManager.swift   # Carbon hotkey monitor & Finder selection tracking
│   ├── SettingsManager.swift       # Shared App Group settings persistence
│   └── FileItem.swift              # Built-in catalog of 34+ file types
│
├── MacNewFileFinderExtension/      # Sandboxed FinderSync Plugin
│   ├── FinderSync.m                # Context menu, dynamic icons, path capture
│   └── Blank.*                     # Blank office document templates
│
├── docs/                           # GitHub Pages Product Documentation
│   ├── index.html                  # Unslopped showcase & setup guide
│   ├── style.css                   # Authentic Apple Cupertino design system
│   └── app.js                      # Responsive interactive catalog & terminal preview
│
├── scripts/
│   └── build.sh                    # CLI compilation & packaging script
│
└── tests/
    └── run_full_test_sweep.swift   # 180-point automated test sweep
```

---

## FAQ & Troubleshooting

<details>
<summary><strong>The "New File" option does not appear when right-clicking in Finder.</strong></summary>

1. Ensure the extension is enabled in **System Settings → General → Login Items & Extensions → Finder Extensions**.
2. Restart Finder by running `killall Finder` in Terminal.
3. Verify that `MacNewFile.app` is running in your menu bar (look for the `+` icon).
</details>

<details>
<summary><strong>Option + Space does not open the Quick Editor.</strong></summary>

1. Ensure `MacNewFile.app` has Accessibility permissions in **System Settings → Privacy & Security → Accessibility**.
2. Check that the selected file format is enabled under the **Quick Editor** column in MacNewFile Settings (`⌘,`).
3. You can customize the shortcut in Settings if `⌥ Space` conflicts with Raycast, Alfred, or Spotlight.
</details>

<details>
<summary><strong>Why is an xattr command needed for direct download?</strong></summary>

Apple requires developers to pay an annual $99 USD developer subscription to obtain official Notarization tickets. As 100% free software, MacNewFile is signed with an ad-hoc certificate. Running:
```bash
xattr -dr com.apple.quarantine /Applications/MacNewFile.app
```
removes macOS Gatekeeper's quarantine attribute and allows the application to run natively.
</details>

---

## Contributing

We welcome contributions, bug reports, and suggestions. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) before opening a pull request.

- Check progress against the [Open Source Project Checklist](./CHECKLIST.md).
- Report security issues following our [Security Policy](./SECURITY.md).

---

## License

MacNewFile is licensed under the **GNU General Public License v3.0** (`GPL-3.0`). See the [LICENSE](./LICENSE) file for details.
