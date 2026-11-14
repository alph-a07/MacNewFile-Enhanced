# Contributing to MacNewFile Enhanced

Thank you for your interest in contributing to **MacNewFile Enhanced**! We welcome bug fixes, documentation improvements, new file types, and feature enhancements.

---

## Code of Conduct

This project and everyone participating in it is governed by the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## Development Setup

### Prerequisites
- **macOS**: macOS 13.0 (Ventura) or newer (macOS 14+ recommended)
- **Toolchain**: Apple Xcode Command Line Tools (`xcode-select --install`) or full Xcode 15+
- **Architecture**: Apple Silicon (`arm64`) or Intel (`x86_64`)

### Getting the Code
1. Fork the repository on GitHub: [https://github.com/alph-a07/MacNewFile-Enhanced](https://github.com/alph-a07/MacNewFile-Enhanced)
2. Clone your fork locally:
   ```bash
   git clone https://github.com/alph-a07/MacNewFile-Enhanced.git
   cd MacNewFile-Enhanced
   ```

---

## Building Locally

MacNewFile Enhanced includes an automated CLI build script that compiles both the main SwiftUI application and the sandboxed FinderSync extension directly using clang and swiftc:

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

This compiles:
1. `MacNewFileFinderExtension.appex` (sandboxed Mach-O executable with `FinderSync` framework)
2. `MacNewFile` main binary (Objective-C runtime and Swift modules)
3. Code-signs all bundles with ad-hoc certificates
4. Packages `dist/MacNewFile.zip`
5. Installs the app into `/Applications/MacNewFile.app` and registers the plugin with LaunchServices.

---

## Running Automated Tests

MacNewFile Enhanced features a comprehensive 180-test verification suite that exercises all hotkeys, extension resolution, multi-document management, terminal integration, and Apple HIG formatting:

```bash
swift tests/run_full_test_sweep.swift
```

Ensure all tests pass (`180/180 passed`) before submitting any pull request.

---

## Making Changes

1. Create a descriptive feature branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. Make your changes and test them locally.
3. If adding a new file type:
   - Update `MacNewFile/FileItem.swift` catalog if it should be built-in.
   - Provide an appropriate SF Symbol icon and default extension mapping.
   - Verify both "New File" context menu and "Quick Editor" preview.
4. Run the full test sweep to ensure zero regressions:
   ```bash
   swift tests/run_full_test_sweep.swift
   ```
5. Commit your changes with clear, semantic commit messages:
   ```bash
   git commit -m "feat(quick-editor): add support for rust and go file types"
   ```
6. Push to your branch on GitHub:
   ```bash
   git push origin feature/my-new-feature
   ```
7. Open a **Pull Request** against the `main` branch.

---

## Pull Request Guidelines

- Keep pull requests focused on a single logical change or feature.
- Follow macOS Human Interface Guidelines (HIG) for all UI changes.
- Ensure `./scripts/build.sh` completes cleanly without warnings.
- Fill out the [Pull Request Template](.github/pull_request_template.md).

---

## Reporting Issues

Found a bug or have a suggestion?
- [Submit a Bug Report](https://github.com/alph-a07/MacNewFile-Enhanced/issues/new?template=bug_report.md)
- [Propose a Feature Request](https://github.com/alph-a07/MacNewFile-Enhanced/issues/new?template=feature_request.md)
- [Join GitHub Discussions](https://github.com/alph-a07/MacNewFile-Enhanced/discussions)
