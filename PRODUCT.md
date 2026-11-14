# Product Specification

## Platform
- macOS Native App & Finder Extension (Swift & Objective-C)
- GitHub Pages Product Website & Documentation (`docs/`)

## Architecture & Stack
- **Native macOS**: Cocoa, SwiftUI, FinderSync framework, Carbon Global Hotkeys.
- **Web / Documentation**: Semantic HTML5, modern vanilla CSS3 with custom properties, zero external runtime dependencies, ultra-fast and responsive.

## Target Audience
- macOS software engineers, power users, designers, system administrators, and former Windows/Linux users who miss instant right-click file creation and need an in-place, editable Quick Look experience in Finder.

## Value Proposition
- Instant file creation across 34+ curated formats directly from Finder's contextual menu.
- Lightweight floating Quick Editor (`⌥ Space`) with real-time Finder selection sync, multi-tab editing, and external editor integration without launching a heavy IDE.

## Core Capabilities
1. **Right-Click Context Menu**: Native FinderSync extension creating valid boilerplate files and Office/iWork templates.
2. **In-Place Quick Editor**: Floating Quick Look-style editor triggered by `⌥ Space` with arrow-key Finder selection tracking.
3. **Independent Format Controls**: Granular enablement of file types for New File vs. Quick Editor.
4. **Terminal Integration**: Jump to active folder in 8+ terminal emulators.
5. **System Fonts & Customization**: Full system font access (SF Mono, Menlo, JetBrains Mono), line numbering, themes, and soft wrap.

## User Onboarding & Guidance Flow
1. **Install**: Direct release `.zip` or Homebrew cask install.
2. **Activate Finder Extension**: Explicit toggle in `System Settings → General → Login Items & Extensions → Finder Extensions`.
3. **Grant Accessibility**: Authorize in `System Settings → Privacy & Security → Accessibility` to enable the global `⌥ Space` hotkey.
4. **Verify**: Test sweep tool (`swift tests/run_full_test_sweep.swift`) validates 180 points of functionality.

## Brand Principles
- **Apple Native Craft**: Strict adherence to Apple Human Interface Guidelines (San Francisco typography, quiet chrome, graphite neutral ramps, tactile keycaps).
- **Zero Slop**: No hue gradients, no glowing halos, no hype copy, no repetitive badges, no emojis in tables or interfaces.
- **Performance & Privacy**: Sub-millisecond execution, zero analytics or telemetry, 100% Free & Open Source under GNU GPL-3.0.
