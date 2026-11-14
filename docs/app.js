/**
 * MacNewFile Enhanced — Unslopt Product Site Scripts
 * Real interactions, real screenshots, zero slop.
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Theme Management (Dark / Light)
  const themeToggle = document.getElementById('themeToggleBtn');
  const storedTheme = localStorage.getItem('mnf-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', storedTheme);

  if (themeToggle) {
    const updateIcon = (theme) => {
      themeToggle.innerHTML = theme === 'dark'
        ? `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`
        : `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`;
    };
    updateIcon(storedTheme);

    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme');
      const next = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('mnf-theme', next);
      updateIcon(next);
    });
  }

  // 2. Homebrew Command Copy
  const brewPill = document.getElementById('brewCommandPill');
  if (brewPill) {
    brewPill.addEventListener('click', async () => {
      const cmd = 'brew install --cask macnewfile';
      try {
        await navigator.clipboard.writeText(cmd);
        const originalHtml = brewPill.innerHTML;
        brewPill.innerHTML = `
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#30d158" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
          <span style="color:#30d158;font-weight:600;">Copied</span>
        `;
        setTimeout(() => {
          brewPill.innerHTML = originalHtml;
        }, 2000);
      } catch (err) {
        console.error('Copy failed:', err);
      }
    });
  }

  // 3. Hero Real Screenshot Switcher
  const shotTabs = document.querySelectorAll('.screenshot-tab-btn');
  const heroImg = document.getElementById('mainHeroScreenshot');
  const captionText = document.getElementById('screenshotCaptionText');

  const shots = {
    'shot-finder': {
      src: 'assets/finder-context-menu.jpg',
      alt: 'Native macOS Finder contextual menu showing New File submenu',
      caption: 'Native macOS Finder contextual menu showing "New File" submenu with 34+ curated file types.'
    },
    'shot-qe': {
      src: 'assets/quick-editor-window.png',
      alt: 'MacNewFile Quick Editor floating panel over Finder',
      caption: 'In-place Quick Editor panel triggered with Option + Space, featuring syntax line numbers and in-place ⌘S saving.'
    }
  };

  shotTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      shotTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const key = tab.getAttribute('data-shot');
      const data = shots[key];
      if (heroImg && data) {
        heroImg.src = data.src;
        heroImg.alt = data.alt;
      }
      if (captionText && data) {
        captionText.textContent = data.caption;
      }
    });
  });

  // 4. File Types Directory
  const catalogData = [
    { name: "Python Script", ext: ".py", cat: "dev", type: "Code & Web" },
    { name: "JavaScript File", ext: ".js", cat: "dev", type: "Code & Web" },
    { name: "TypeScript File", ext: ".ts", cat: "dev", type: "Code & Web" },
    { name: "HTML Document", ext: ".html", cat: "dev", type: "Code & Web" },
    { name: "CSS Stylesheet", ext: ".css", cat: "dev", type: "Code & Web" },
    { name: "JSON Document", ext: ".json", cat: "dev", type: "Code & Web" },
    { name: "YAML Configuration", ext: ".yaml", cat: "dev", type: "Code & Web" },
    { name: "Shell Script", ext: ".sh", cat: "dev", type: "Code & Web" },
    { name: "Swift Source", ext: ".swift", cat: "dev", type: "Code & Web" },
    { name: "Rust Source", ext: ".rs", cat: "dev", type: "Code & Web" },
    { name: "Go Source", ext: ".go", cat: "dev", type: "Code & Web" },
    { name: "C Source", ext: ".c", cat: "dev", type: "Code & Web" },
    { name: "C++ Source", ext: ".cpp", cat: "dev", type: "Code & Web" },
    { name: "C Header", ext: ".h", cat: "dev", type: "Code & Web" },
    { name: "SQL Query", ext: ".sql", cat: "dev", type: "Code & Web" },
    { name: "XML Document", ext: ".xml", cat: "dev", type: "Code & Web" },
    { name: "Markdown Document", ext: ".md", cat: "docs", type: "Documents" },
    { name: "Plain Text Document", ext: ".txt", cat: "docs", type: "Documents" },
    { name: "Rich Text Document", ext: ".rtf", cat: "docs", type: "Documents" },
    { name: "Word Document", ext: ".docx", cat: "docs", type: "Office Template" },
    { name: "Excel Spreadsheet", ext: ".xlsx", cat: "docs", type: "Office Template" },
    { name: "PowerPoint Slides", ext: ".pptx", cat: "docs", type: "Office Template" },
    { name: "Apple Pages Document", ext: ".pages", cat: "docs", type: "iWork Template" },
    { name: "Apple Numbers Sheet", ext: ".numbers", cat: "docs", type: "iWork Template" },
    { name: "Apple Keynote Deck", ext: ".key", cat: "docs", type: "iWork Template" },
    { name: "CSV Spreadsheet", ext: ".csv", cat: "sys", type: "Data & Config" },
    { name: "TSV Spreadsheet", ext: ".tsv", cat: "sys", type: "Data & Config" },
    { name: "Environment File", ext: ".env", cat: "sys", type: "Data & Config" },
    { name: "INI Configuration", ext: ".ini", cat: "sys", type: "Data & Config" },
    { name: "TOML Configuration", ext: ".toml", cat: "sys", type: "Data & Config" },
    { name: "Log Output File", ext: ".log", cat: "sys", type: "Data & Config" },
    { name: "Git Ignore File", ext: ".gitignore", cat: "sys", type: "Data & Config" },
    { name: "Zsh Configuration", ext: ".zshrc", cat: "sys", type: "Data & Config" },
    { name: "Custom Extensions", ext: ".*", cat: "custom", type: "User Defined" }
  ];

  const grid = document.getElementById('catalogGrid');
  const searchInput = document.getElementById('catalogSearchField');
  const filterBtns = document.querySelectorAll('.filter-btn');
  let activeCat = 'all';

  const renderGrid = () => {
    if (!grid) return;
    const q = (searchInput?.value || '').toLowerCase().trim();

    const matches = catalogData.filter(item => {
      const matchCat = activeCat === 'all' || item.cat === activeCat;
      const matchText = !q || item.name.toLowerCase().includes(q) || item.ext.toLowerCase().includes(q);
      return matchCat && matchText;
    });

    grid.innerHTML = matches.map(item => `
      <div class="catalog-card">
        <div>
          <div class="card-title">${item.name}</div>
          <div class="card-ext">${item.ext}</div>
        </div>
        <span class="card-tag">${item.type}</span>
      </div>
    `).join('');
  };

  renderGrid();

  if (searchInput) searchInput.addEventListener('input', renderGrid);

  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeCat = btn.getAttribute('data-cat') || 'all';
      renderGrid();
    });
  });

  // 5. Terminal Showcase Switcher
  const termBtns = document.querySelectorAll('.term-tab-pill');
  const termHeader = document.getElementById('termHeaderLabel');
  const termOutput = document.getElementById('termCommandOutput');

  const terms = {
    'ghostty': { label: 'Ghostty — zsh (Native Metal GPU)', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Ghostty .' },
    'iterm': { label: 'iTerm2 — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a iTerm .' },
    'terminal': { label: 'Terminal.app — zsh (Default)', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Terminal .' },
    'warp': { label: 'Warp — zsh (AI Terminal)', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Warp .' },
    'alacritty': { label: 'Alacritty — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && alacritty --working-directory .' },
    'kitty': { label: 'kitty — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && kitty --directory .' },
    'wezterm': { label: 'WezTerm — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && wezterm start --cwd .' }
  };

  termBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      termBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const key = btn.getAttribute('data-term');
      const data = terms[key] || terms['ghostty'];
      if (termHeader) termHeader.textContent = data.label;
      if (termOutput) termOutput.textContent = data.cmd;
    });
  });

  // 6. Installation Tabs
  const installBtns = document.querySelectorAll('.install-tab-btn');
  const installPanels = document.querySelectorAll('.install-panel');

  installBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      installBtns.forEach(b => b.classList.remove('active'));
      installPanels.forEach(p => p.style.display = 'none');
      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.style.display = 'block';
    });
  });

  // 7. FAQ Accordion
  document.querySelectorAll('.faq-header-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const row = btn.closest('.faq-row');
      if (row) {
        row.classList.toggle('open');
      }
    });
  });
});
