# Open Source Project Checklist

This checklist tracks the product readiness and open-source standards of **MacNewFile Enhanced**, referenced from [libresource/open-source-checklist](https://github.com/libresource/open-source-checklist).

---

## 1. Project Foundations & Mission
- [x] **Project Name**: MacNewFile Enhanced
- [x] **Clear Pitch & Mission Statement**: A lightweight, native macOS menu bar and Finder companion that brings instant right-click file creation and an in-place, editable Quick Look editor to Finder.
- [x] **Existing Analogues & Differentiation**: Documented in `README.md` (macOS Finder limitations vs. Windows context menu; Quick Look read-only vs. MacNewFile in-place Quick Editor).
- [x] **FOSS Commitment**: 100% Free and Open Source Software licensed under the GNU General Public License v3.0 (`GPL-3.0`).

---

## 2. Documentation & Guides
- [x] **GitHub Pages Site**: Deployed at [https://alph-a07.github.io/MacNewFile-Enhanced/](https://alph-a07.github.io/MacNewFile-Enhanced/) with live interactive macOS Finder and Quick Editor simulator, 34+ file type explorer, and terminal selector.
- [x] **Comprehensive README.md**:
  - [x] Badges (CI status, Releases, License, macOS compatibility, Architecture).
  - [x] Feature highlights with screenshots and visual demonstrations.
  - [x] System requirements (macOS 11.0+, Apple Silicon & Intel).
  - [x] Installation options (GitHub Releases `.zip`, CLI build, Homebrew).
  - [x] Keyboard shortcuts reference table.
  - [x] Architecture & Tech stack breakdown.
  - [x] Troubleshooting & FAQ section.
- [x] **Contributor Guidelines (`CONTRIBUTING.md`)**:
  - [x] Local development environment setup.
  - [x] Building with `./scripts/build.sh`.
  - [x] Running automated test sweep (`swift tests/run_full_test_sweep.swift`).
  - [x] Code style and branch workflow.
- [x] **Code of Conduct (`CODE_OF_CONDUCT.md`)**: Contributor Covenant v2.1 adopted.
- [x] **Security Policy (`SECURITY.md`)**: Vulnerability disclosure instructions and SLAs.
- [x] **Changelog (`CHANGELOG.md`)**: Keep a Changelog standard format.

---

## 3. Community & Governance
- [x] **Issue Templates (`.github/ISSUE_TEMPLATE/`)**:
  - [x] `bug_report.md`: Structured form with macOS version, reproduction steps, logs, and screenshots.
  - [x] `feature_request.md`: Structured feature proposals for new file formats, editor capabilities, or terminal apps.
  - [x] `config.yml`: Guidance pointing to GitHub Discussions.
- [x] **Pull Request Template (`.github/pull_request_template.md`)**: Comprehensive testing and verification checklist.
- [x] **Funding Configuration (`.github/FUNDING.yml`)**: Community support link.
- [x] **Open Source License (`LICENSE`)**: GNU General Public License v3.0 (`GPL-3.0`).

---

## 4. Automation & CI/CD
- [x] **Continuous Integration (`.github/workflows/ci.yml`)**:
  - [x] Runs on `macos-14` (Apple Silicon runner).
  - [x] Compiles the application and Finder extension with `./scripts/build.sh`.
  - [x] Executes full 180-test automated verification suite (`swift tests/run_full_test_sweep.swift`).
  - [x] Uploads built artifacts.
- [x] **Release Packaging (`.github/workflows/release.yml`)**:
  - [x] Automatically triggered on version tags (`v*`).
  - [x] Compiles and zips `MacNewFile.app`.
  - [x] Creates GitHub Release with checksums and release notes.

---

## 5. Quality Assurance & Product Polish
- [x] **Automated Test Coverage**: 180 / 180 tests passing in full test sweep.
- [x] **Apple HIG Compliance**:
  - [x] Dynamic template icon tinting matching system light/dark mode.
  - [x] Native SF Symbols icons.
  - [x] Refined Settings UI with native segmented toolbar.
  - [x] Fluid opening/closing spring animations.
- [x] **Zero Memory/Resource Leaks**: Clean FinderSync lifecycle and debounced document polling.
