/**
 * MacNewFile Enhanced — Official Product Website Controller
 * Craft: Impeccable Sequoia System Interface
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Theme Management (System / Dark / Light)
  const themeToggle = document.getElementById('themeToggleBtn');
  const storedTheme = localStorage.getItem('mnf-site-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', storedTheme);

  if (themeToggle) {
    const updateIcon = (theme) => {
      themeToggle.innerHTML = theme === 'dark' 
        ? `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`
        : `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`;
    };
    updateIcon(storedTheme);

    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme');
      const next = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('mnf-site-theme', next);
      updateIcon(next);
    });
  }

  // 2. Homebrew Command Copy Pill
  const brewPill = document.getElementById('brewCommandPill');
  if (brewPill) {
    brewPill.addEventListener('click', async () => {
      const cmd = 'brew install --cask macnewfile';
      try {
        await navigator.clipboard.writeText(cmd);
        const originalHtml = brewPill.innerHTML;
        brewPill.innerHTML = `
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#34c759" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
          <span style="color:#34c759;font-weight:600;">Copied to clipboard</span>
        `;
        setTimeout(() => {
          brewPill.innerHTML = originalHtml;
        }, 2000);
      } catch (err) {
        console.error('Copy failed:', err);
      }
    });
  }

  // 3. Hero Visual Stage Switcher (Right-Click Context Menu vs Quick Editor)
  const stageTabs = document.querySelectorAll('.stage-tab-btn');
  const contextShowcase = document.getElementById('heroContextMenuView');
  const qeShowcase = document.getElementById('heroQuickEditorView');

  stageTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      stageTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const view = tab.getAttribute('data-view');
      if (view === 'context') {
        if (contextShowcase) contextShowcase.style.display = 'block';
        if (qeShowcase) qeShowcase.style.display = 'none';
      } else {
        if (contextShowcase) contextShowcase.style.display = 'none';
        if (qeShowcase) qeShowcase.style.display = 'flex';
      }
    });
  });

  // 4. File Types Catalog Data & Search
  const fileCatalogData = [
    { name: "Python Script", ext: ".py", cat: "dev", icon: "PY" },
    { name: "JavaScript File", ext: ".js", cat: "dev", icon: "JS" },
    { name: "TypeScript File", ext: ".ts", cat: "dev", icon: "TS" },
    { name: "HTML Document", ext: ".html", cat: "dev", icon: "HTML" },
    { name: "CSS Stylesheet", ext: ".css", cat: "dev", icon: "CSS" },
    { name: "JSON Document", ext: ".json", cat: "dev", icon: "JSON" },
    { name: "YAML Configuration", ext: ".yaml", cat: "dev", icon: "YAML" },
    { name: "Shell Script", ext: ".sh", cat: "dev", icon: "SH" },
    { name: "Swift Source", ext: ".swift", cat: "dev", icon: "SWIFT" },
    { name: "Rust Source", ext: ".rs", cat: "dev", icon: "RS" },
    { name: "Go Source", ext: ".go", cat: "dev", icon: "GO" },
    { name: "C Source", ext: ".c", cat: "dev", icon: "C" },
    { name: "C++ Source", ext: ".cpp", cat: "dev", icon: "CPP" },
    { name: "C Header", ext: ".h", cat: "dev", icon: "H" },
    { name: "SQL Query", ext: ".sql", cat: "dev", icon: "SQL" },
    { name: "XML Document", ext: ".xml", cat: "dev", icon: "XML" },
    { name: "Markdown Document", ext: ".md", cat: "docs", icon: "MD" },
    { name: "Plain Text Document", ext: ".txt", cat: "docs", icon: "TXT" },
    { name: "Rich Text Document", ext: ".rtf", cat: "docs", icon: "RTF" },
    { name: "Word Document", ext: ".docx", cat: "docs", icon: "DOCX" },
    { name: "Excel Spreadsheet", ext: ".xlsx", cat: "docs", icon: "XLSX" },
    { name: "PowerPoint Slides", ext: ".pptx", cat: "docs", icon: "PPTX" },
    { name: "Apple Pages Document", ext: ".pages", cat: "docs", icon: "PAGES" },
    { name: "Apple Numbers Sheet", ext: ".numbers", cat: "docs", icon: "NUM" },
    { name: "Apple Keynote Deck", ext: ".key", cat: "docs", icon: "KEY" },
    { name: "CSV Spreadsheet", ext: ".csv", cat: "sys", icon: "CSV" },
    { name: "TSV Spreadsheet", ext: ".tsv", cat: "sys", icon: "TSV" },
    { name: "Environment File", ext: ".env", cat: "sys", icon: "ENV" },
    { name: "INI Configuration", ext: ".ini", cat: "sys", icon: "INI" },
    { name: "TOML Configuration", ext: ".toml", cat: "sys", icon: "TOML" },
    { name: "Log Output File", ext: ".log", cat: "sys", icon: "LOG" },
    { name: "Git Ignore File", ext: ".gitignore", cat: "sys", icon: "GIT" },
    { name: "Zsh Configuration", ext: ".zshrc", cat: "sys", icon: "ZSH" },
    { name: "Custom Extensions", ext: ".*", cat: "custom", icon: "ADD" }
  ];

  const catalogGrid = document.getElementById('catalogCardsGrid');
  const catInput = document.getElementById('catalogSearchInput');
  const catButtons = document.querySelectorAll('.cat-btn');
  let currentCategory = 'all';

  const renderCatalog = () => {
    if (!catalogGrid) return;
    const q = (catInput?.value || '').toLowerCase().trim();

    const matches = fileCatalogData.filter(item => {
      const catMatch = currentCategory === 'all' || item.cat === currentCategory;
      const textMatch = !q || item.name.toLowerCase().includes(q) || item.ext.toLowerCase().includes(q);
      return catMatch && textMatch;
    });

    catalogGrid.innerHTML = matches.map(item => `
      <div class="cat-item-card">
        <div class="cat-item-info">
          <div class="cat-icon-chip">${item.icon}</div>
          <div>
            <div class="cat-title">${item.name}</div>
            <div class="cat-ext">${item.ext}</div>
          </div>
        </div>
        <span class="cat-capsule">Native HIG</span>
      </div>
    `).join('');
  };

  renderCatalog();

  if (catInput) catInput.addEventListener('input', renderCatalog);

  catButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      catButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentCategory = btn.getAttribute('data-cat') || 'all';
      renderCatalog();
    });
  });

  // 5. Terminal Showcase Switcher
  const termButtons = document.querySelectorAll('.term-choice-btn');
  const termTitle = document.getElementById('terminalHeaderTitle');
  const termCmd = document.getElementById('terminalCommandOutput');

  const termMap = {
    'ghostty': { title: 'Ghostty — zsh (Native Metal)', cmd: 'open -a Ghostty .' },
    'iterm': { title: 'iTerm2 — zsh', cmd: 'open -a iTerm .' },
    'terminal': { title: 'Terminal.app — zsh (Default)', cmd: 'open -a Terminal .' },
    'warp': { title: 'Warp — zsh (AI Terminal)', cmd: 'open -a Warp .' },
    'alacritty': { title: 'Alacritty — zsh (GPU-Accelerated)', cmd: 'alacritty --working-directory .' },
    'kitty': { title: 'kitty — zsh (OpenGL)', cmd: 'kitty --directory .' },
    'wezterm': { title: 'WezTerm — zsh', cmd: 'wezterm start --cwd .' }
  };

  termButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      termButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const key = btn.getAttribute('data-term');
      const data = termMap[key] || termMap['ghostty'];
      if (termTitle) termTitle.textContent = data.title;
      if (termCmd) termCmd.textContent = `cd ~/Developer/MacNewFile-Enhanced && ${data.cmd}`;
    });
  });

  // 6. Installation Tab Navigator
  const installTabs = document.querySelectorAll('.install-tab-button');
  const installPanes = document.querySelectorAll('.install-tab-pane');

  installTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      installTabs.forEach(t => t.classList.remove('active'));
      installPanes.forEach(p => p.style.display = 'none');
      tab.classList.add('active');
      const targetId = tab.getAttribute('data-tab');
      const targetPane = document.getElementById(targetId);
      if (targetPane) targetPane.style.display = 'block';
    });
  });

  // 7. FAQ Accordion
  document.querySelectorAll('.faq-trigger').forEach(trigger => {
    trigger.addEventListener('click', () => {
      const card = trigger.closest('.faq-card');
      if (card) {
        card.classList.toggle('open');
      }
    });
  });
});
