/**
 * MacNewFile Enhanced — Live Interactive Controller
 * Mode: Persuade | Theme: macOS Sequoia Simulation
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Live Clock
  const timeEl = document.getElementById('liveClock');
  const updateClock = () => {
    if (!timeEl) return;
    const now = new Date();
    const options = { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' };
    timeEl.textContent = now.toLocaleDateString('en-US', options).replace(/,/g, '');
  };
  updateClock();
  setInterval(updateClock, 30000);

  // 2. Dark / Light Theme Toggle
  const themeToggle = document.getElementById('themeToggle');
  const currentTheme = localStorage.getItem('mnf-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', currentTheme);
  
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme');
      const next = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('mnf-theme', next);
      themeToggle.textContent = next === 'dark' ? '􀆭' : '􀆮';
    });
  }

  // 3. One-Click Copy for Terminal CLI
  const copyPill = document.getElementById('cliCopyPill');
  if (copyPill) {
    copyPill.addEventListener('click', async () => {
      const textToCopy = 'brew tap alph-a07/macnewfile && brew install macnewfile';
      try {
        await navigator.clipboard.writeText(textToCopy);
        const originalText = copyPill.innerHTML;
        copyPill.innerHTML = '<span style="color:var(--accent-green)">✓ Copied to Clipboard</span>';
        setTimeout(() => {
          copyPill.innerHTML = originalText;
        }, 2200);
      } catch (err) {
        console.error('Clipboard copy failed:', err);
      }
    });
  }

  // 4. File Types Catalog Data
  const fileCatalog = [
    // Code & Web
    { name: "Python Script", ext: ".py", cat: "code", icon: "py", newFile: true, qe: true },
    { name: "JavaScript File", ext: ".js", cat: "code", icon: "js", newFile: true, qe: true },
    { name: "TypeScript File", ext: ".ts", cat: "code", icon: "ts", newFile: true, qe: true },
    { name: "HTML Document", ext: ".html", cat: "code", icon: "html", newFile: true, qe: true },
    { name: "CSS Stylesheet", ext: ".css", cat: "code", icon: "css", newFile: true, qe: true },
    { name: "JSON File", ext: ".json", cat: "code", icon: "json", newFile: true, qe: true },
    { name: "YAML File", ext: ".yaml", cat: "code", icon: "yaml", newFile: true, qe: true },
    { name: "Shell Script", ext: ".sh", cat: "code", icon: "sh", newFile: true, qe: true },
    { name: "Swift Source", ext: ".swift", cat: "code", icon: "swift", newFile: true, qe: true },
    { name: "C Source", ext: ".c", cat: "code", icon: "c", newFile: true, qe: true },
    { name: "C++ Source", ext: ".cpp", cat: "code", icon: "cpp", newFile: true, qe: true },
    { name: "C Header", ext: ".h", cat: "code", icon: "h", newFile: true, qe: true },
    { name: "Rust Source", ext: ".rs", cat: "code", icon: "rs", newFile: true, qe: true },
    { name: "Go Source", ext: ".go", cat: "code", icon: "go", newFile: true, qe: true },
    { name: "SQL Query", ext: ".sql", cat: "code", icon: "sql", newFile: true, qe: true },
    { name: "XML Document", ext: ".xml", cat: "code", icon: "xml", newFile: true, qe: true },

    // Documents & Notes
    { name: "Plain Text Document", ext: ".txt", cat: "docs", icon: "txt", newFile: true, qe: true },
    { name: "Markdown Document", ext: ".md", cat: "docs", icon: "md", newFile: true, qe: true },
    { name: "Rich Text Document", ext: ".rtf", cat: "docs", icon: "rtf", newFile: true, qe: true },
    { name: "Word Document", ext: ".docx", cat: "docs", icon: "docx", newFile: true, qe: false },
    { name: "Excel Spreadsheet", ext: ".xlsx", cat: "docs", icon: "xlsx", newFile: true, qe: false },
    { name: "PowerPoint Presentation", ext: ".pptx", cat: "docs", icon: "pptx", newFile: true, qe: false },
    { name: "Pages Document", ext: ".pages", cat: "docs", icon: "pages", newFile: true, qe: false },
    { name: "Numbers Spreadsheet", ext: ".numbers", cat: "docs", icon: "numbers", newFile: true, qe: false },
    { name: "Keynote Presentation", ext: ".key", cat: "docs", icon: "key", newFile: true, qe: false },

    // Data & Config
    { name: "CSV Spreadsheet", ext: ".csv", cat: "data", icon: "csv", newFile: true, qe: true },
    { name: "TSV Spreadsheet", ext: ".tsv", cat: "data", icon: "tsv", newFile: true, qe: true },
    { name: "Environment Config", ext: ".env", cat: "data", icon: "env", newFile: true, qe: true },
    { name: "INI Configuration", ext: ".ini", cat: "data", icon: "ini", newFile: true, qe: true },
    { name: "TOML Configuration", ext: ".toml", cat: "data", icon: "toml", newFile: true, qe: true },
    { name: "Log File", ext: ".log", cat: "data", icon: "log", newFile: true, qe: true },
    { name: "Git Ignore File", ext: ".gitignore", cat: "data", icon: "git", newFile: false, qe: true },
    { name: "Zsh Configuration", ext: ".zshrc", cat: "data", icon: "zsh", newFile: false, qe: true },
    { name: "Custom Types", ext: ".*", cat: "custom", icon: "custom", newFile: true, qe: true }
  ];

  // Render Catalog Cards
  const cardsGrid = document.getElementById('fileCardsGrid');
  const searchInput = document.getElementById('catalogSearch');
  const catButtons = document.querySelectorAll('.cat-tab-btn');
  let activeCategory = 'all';

  const renderCards = () => {
    if (!cardsGrid) return;
    const query = (searchInput?.value || '').toLowerCase().trim();
    
    const filtered = fileCatalog.filter(item => {
      const matchesCat = activeCategory === 'all' || item.cat === activeCategory;
      const matchesQuery = !query || 
        item.name.toLowerCase().includes(query) || 
        item.ext.toLowerCase().includes(query);
      return matchesCat && matchesQuery;
    });

    cardsGrid.innerHTML = filtered.map(item => `
      <div class="file-type-card">
        <div class="file-info-group">
          <div class="card-icon-pill">${item.icon.toUpperCase()}</div>
          <div>
            <div class="card-text-title">${item.name}</div>
            <div class="card-text-ext">${item.ext}</div>
          </div>
        </div>
        <div class="toggles-group">
          <span class="switch-pill" title="Enabled for Finder Right-Click">${item.newFile ? '✓ New File' : 'Off'}</span>
          <span class="switch-pill" style="${item.qe ? '' : 'opacity:0.4'}" title="Enabled for Quick Editor">${item.qe ? '✓ ⌥ Space' : 'Off'}</span>
        </div>
      </div>
    `).join('');
  };

  renderCards();

  if (searchInput) {
    searchInput.addEventListener('input', renderCards);
  }

  catButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      catButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeCategory = btn.getAttribute('data-cat') || 'all';
      renderCards();
    });
  });

  // 5. Interactive macOS Finder Simulator
  const finderCanvas = document.getElementById('finderCanvas');
  const contextMenu = document.getElementById('finderContextMenu');
  const qePanel = document.getElementById('quickEditorPanel');
  const qeCloseBtn = document.getElementById('qeCloseBtn');
  const qeTextarea = document.getElementById('qeTextarea');
  const qeLineNumbers = document.getElementById('qeLineNumbers');
  const qeStatusText = document.getElementById('qeStatusText');
  const triggerMenuBtn = document.getElementById('triggerContextMenuBtn');
  const triggerQeBtn = document.getElementById('triggerQuickEditorBtn');

  // File document contents for simulated Quick Editor
  const docContents = {
    'main.py': `# MacNewFile Automation Helper\nimport sys\nimport os\n\ndef main():\n    print("Welcome to MacNewFile Quick Editor!")\n    print("Edit your files in-place with instant ⌘S saving.")\n\nif __name__ == '__main__':\n    main()\n`,
    'config.yaml': `version: 3.2.0\napp:\n  name: MacNewFile Enhanced\n  license: GPL-3.0\n  author: alph-a07\nfeatures:\n  quick_editor: true\n  right_click_menu: true\n  independent_toggles: true\n  custom_terminal: "Ghostty"\n`,
    'README.md': `# MacNewFile Enhanced\n\nInstant right-click file creation and in-place Quick Look editor for macOS Finder.\n\n- 34+ File Types\n- Option + Space Quick Editor\n- Custom Terminal Integration\n- 100% Free & Open Source\n`,
    'style.css': `/* Sequoia Translucent Material */\n.finder-panel {\n    backdrop-filter: blur(28px) saturate(180%);\n    border: 1px solid rgba(255, 255, 255, 0.12);\n    border-radius: 12px;\n    box-shadow: 0 24px 64px rgba(0, 0, 0, 0.45);\n}\n`
  };

  let selectedFile = 'main.py';

  const updateLineNumbers = () => {
    if (!qeTextarea || !qeLineNumbers) return;
    const lines = (qeTextarea.value || '').split('\n').length;
    let numbersHtml = '';
    for (let i = 1; i <= Math.max(lines, 12); i++) {
      numbersHtml += `<div>${i}</div>`;
    }
    qeLineNumbers.innerHTML = numbersHtml;
    if (qeStatusText) {
      qeStatusText.textContent = `Lines: ${lines}  |  Chars: ${qeTextarea.value.length}  |  UTF-8`;
    }
  };

  const openQuickEditor = (filename) => {
    selectedFile = filename || selectedFile;
    if (!qePanel || !qeTextarea) return;
    qeTextarea.value = docContents[selectedFile] || `# ${selectedFile}\n// Newly created file. Start typing...\n`;
    updateLineNumbers();
    qePanel.classList.add('active');
    contextMenu.style.display = 'none';
  };

  const closeQuickEditor = () => {
    if (qePanel) qePanel.classList.remove('active');
  };

  if (qeCloseBtn) {
    qeCloseBtn.addEventListener('click', closeQuickEditor);
  }

  if (qeTextarea) {
    qeTextarea.addEventListener('input', updateLineNumbers);
  }

  // Handle file item clicks in simulated Finder
  const setupFileSelection = () => {
    document.querySelectorAll('.finder-file-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.stopPropagation();
        document.querySelectorAll('.finder-file-item').forEach(f => f.classList.remove('selected'));
        item.classList.add('selected');
        selectedFile = item.getAttribute('data-filename') || 'main.py';
        contextMenu.style.display = 'none';
      });

      item.addEventListener('dblclick', (e) => {
        e.stopPropagation();
        selectedFile = item.getAttribute('data-filename') || 'main.py';
        openQuickEditor(selectedFile);
      });
    });
  };
  setupFileSelection();

  // Right-click context menu positioning
  if (finderCanvas && contextMenu) {
    finderCanvas.addEventListener('contextmenu', (e) => {
      e.preventDefault();
      const rect = finderCanvas.getBoundingClientRect();
      const x = Math.min(e.clientX - rect.left, rect.width - 240);
      const y = Math.min(e.clientY - rect.top, rect.height - 300);
      contextMenu.style.left = `${Math.max(10, x)}px`;
      contextMenu.style.top = `${Math.max(10, y)}px`;
      contextMenu.style.display = 'block';
    });

    finderCanvas.addEventListener('click', () => {
      contextMenu.style.display = 'none';
    });
  }

  if (triggerMenuBtn && contextMenu && finderCanvas) {
    triggerMenuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      contextMenu.style.left = '140px';
      contextMenu.style.top = '100px';
      contextMenu.style.display = 'block';
    });
  }

  if (triggerQeBtn) {
    triggerQeBtn.addEventListener('click', () => {
      openQuickEditor(selectedFile);
    });
  }

  // Context Menu Submenu Actions
  document.querySelectorAll('.create-file-action').forEach(action => {
    action.addEventListener('click', (e) => {
      e.stopPropagation();
      const filename = action.getAttribute('data-create');
      if (!filename || !finderCanvas) return;

      // Add file to canvas if not already present
      const existing = finderCanvas.querySelector(`[data-filename="${filename}"]`);
      if (!existing) {
        const fileDiv = document.createElement('div');
        fileDiv.className = 'finder-file-item selected';
        fileDiv.setAttribute('data-filename', filename);
        fileDiv.innerHTML = `
          <svg class="file-icon-svg" viewBox="0 0 48 48" fill="none">
            <rect x="6" y="4" width="36" height="40" rx="4" fill="#3a3f52" />
            <path d="M28 4v12h14" fill="#2d3142" />
            <text x="24" y="32" font-size="10" font-weight="700" fill="#2997ff" text-anchor="middle">${filename.split('.').pop().toUpperCase()}</text>
          </svg>
          <div class="file-name-label">${filename}</div>
        `;
        document.querySelectorAll('.finder-file-item').forEach(f => f.classList.remove('selected'));
        finderCanvas.appendChild(fileDiv);
        setupFileSelection();
      }
      contextMenu.style.display = 'none';
      openQuickEditor(filename);
    });
  });

  // Global Keyboard Shortcuts
  window.addEventListener('keydown', (e) => {
    // Option + Space to toggle Quick Editor
    if (e.altKey && e.code === 'Space') {
      e.preventDefault();
      if (qePanel && qePanel.classList.contains('active')) {
        closeQuickEditor();
      } else {
        openQuickEditor(selectedFile);
      }
    }
    // Escape to close Quick Editor
    if (e.key === 'Escape' && qePanel && qePanel.classList.contains('active')) {
      closeQuickEditor();
    }
  });

  // 6. Terminal Selector
  const termButtons = document.querySelectorAll('.term-btn');
  const termNameEl = document.getElementById('termTitleName');
  const termCmdEl = document.getElementById('termCommandDisplay');

  const termData = {
    'terminal': { name: 'Terminal.app — zsh', cmd: 'open -a Terminal "%s"' },
    'iterm': { name: 'iTerm2 — zsh', cmd: 'open -a iTerm "%s"' },
    'ghostty': { name: 'Ghostty — zsh', cmd: 'open -a Ghostty "%s"' },
    'warp': { name: 'Warp — zsh', cmd: 'open -a Warp "%s"' },
    'alacritty': { name: 'Alacritty — zsh', cmd: 'alacritty --working-directory "%s"' },
    'kitty': { name: 'kitty — zsh', cmd: 'kitty --directory "%s"' },
    'wezterm': { name: 'WezTerm — zsh', cmd: 'wezterm start --cwd "%s"' }
  };

  termButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      termButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const termKey = btn.getAttribute('data-term') || 'terminal';
      const info = termData[termKey] || termData['terminal'];
      if (termNameEl) termNameEl.textContent = info.name;
      if (termCmdEl) termCmdEl.textContent = `cd ~/Developer/MacNewFile-Enhanced && ${info.cmd.replace('%s', '.')}`;
    });
  });

  // 7. Installation Tabs
  const installTabs = document.querySelectorAll('.install-tab-btn');
  const installPanels = document.querySelectorAll('.install-tab-content');

  installTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      installTabs.forEach(t => t.classList.remove('active'));
      installPanels.forEach(p => p.style.display = 'none');
      tab.classList.add('active');
      const targetId = tab.getAttribute('data-tab');
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.style.display = 'block';
    });
  });

  // 8. FAQ Accordion
  document.querySelectorAll('.faq-question').forEach(btn => {
    btn.addEventListener('click', () => {
      const parent = btn.closest('.faq-item');
      if (parent) {
        parent.classList.toggle('open');
      }
    });
  });
});
