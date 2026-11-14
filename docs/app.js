/**
 * MacNewFile Enhanced — Client Application Script
 * Authentic interactions, responsive navigation, zero slop.
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Theme Management (Dark / Light)
  const themeToggle = document.getElementById('themeToggleBtn');
  const storedTheme = localStorage.getItem('mnf-theme') || 
    (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
  document.documentElement.setAttribute('data-theme', storedTheme);

  const updateThemeIcon = (theme) => {
    if (!themeToggle) return;
    themeToggle.innerHTML = theme === 'dark'
      ? `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`
      : `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`;
    themeToggle.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`);
  };

  updateThemeIcon(storedTheme);

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const active = document.documentElement.getAttribute('data-theme');
      const next = active === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('mnf-theme', next);
      updateThemeIcon(next);
    });
  }

  // 2. Mobile Menu Navigation Toggle
  const mobileToggleBtn = document.getElementById('mobileMenuBtn');
  const mobileNavDrawer = document.getElementById('mobileNavDrawer');

  if (mobileToggleBtn && mobileNavDrawer) {
    mobileToggleBtn.addEventListener('click', () => {
      const isOpen = mobileNavDrawer.classList.toggle('open');
      mobileToggleBtn.setAttribute('aria-expanded', isOpen);
      mobileToggleBtn.innerHTML = isOpen
        ? `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`
        : `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>`;
    });

    mobileNavDrawer.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        mobileNavDrawer.classList.remove('open');
        mobileToggleBtn.setAttribute('aria-expanded', 'false');
        mobileToggleBtn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>`;
      });
    });
  }

  // 3. Generic Clipboard Copy Helper
  const setupCopyButton = (buttonId, textToCopy) => {
    const btn = document.getElementById(buttonId);
    if (!btn) return;

    btn.addEventListener('click', async () => {
      try {
        const text = typeof textToCopy === 'function' ? textToCopy() : textToCopy;
        await navigator.clipboard.writeText(text);
        const originalContent = btn.innerHTML;
        btn.innerHTML = `
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--semantic-green)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
          <span style="color:var(--semantic-green);font-weight:500;">Copied</span>
        `;
        setTimeout(() => {
          btn.innerHTML = originalContent;
        }, 1800);
      } catch (err) {
        console.error('Copy failed:', err);
      }
    });
  };

  setupCopyButton('brewCommandPill', 'brew install --cask macnewfile');

  // Copy buttons on code snippets
  document.querySelectorAll('.snippet-copy-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const targetSnippet = btn.closest('.code-snippet');
      if (!targetSnippet) return;
      const code = targetSnippet.querySelector('code')?.innerText || targetSnippet.innerText.replace('Copy', '').trim();
      try {
        await navigator.clipboard.writeText(code);
        const origText = btn.textContent;
        btn.textContent = 'Copied';
        btn.style.color = 'var(--semantic-green)';
        setTimeout(() => {
          btn.textContent = origText;
          btn.style.color = '';
        }, 1800);
      } catch (e) {
        console.error(e);
      }
    });
  });

  // 4. Hero Screenshot Switcher
  const shotTabs = document.querySelectorAll('.showcase-tab');
  const heroImg = document.getElementById('mainHeroScreenshot');
  const captionText = document.getElementById('screenshotCaptionText');
  const captionTag = document.getElementById('screenshotCaptionTag');

  const shots = {
    'shot-finder': {
      src: 'assets/finder-context-menu.jpg',
      alt: 'Native macOS Finder context menu with New File submenu',
      caption: 'Native macOS Finder contextual menu showing "New File" submenu with 34+ curated file types.',
      tag: 'Finder Context Menu'
    },
    'shot-qe': {
      src: 'assets/quick-editor-window.png',
      alt: 'MacNewFile Quick Editor floating panel over Finder',
      caption: 'In-place Quick Editor panel triggered with Option + Space, featuring syntax line numbers and in-place ⌘S saving.',
      tag: 'Option + Space Quick Editor'
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
      if (captionTag && data) {
        captionTag.textContent = data.tag;
      }
    });
  });

  // 5. File Formats Catalog
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
    { name: "Microsoft Word", ext: ".docx", cat: "docs", type: "Office Template" },
    { name: "Microsoft Excel", ext: ".xlsx", cat: "docs", type: "Office Template" },
    { name: "Microsoft PowerPoint", ext: ".pptx", cat: "docs", type: "Office Template" },
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
    { name: "Custom User Formats", ext: ".*", cat: "custom", type: "User Defined" }
  ];

  const grid = document.getElementById('catalogGrid');
  const searchInput = document.getElementById('catalogSearchField');
  const filterPills = document.querySelectorAll('.filter-pill');
  let activeCat = 'all';

  const renderGrid = () => {
    if (!grid) return;
    const q = (searchInput?.value || '').toLowerCase().trim();

    const matches = catalogData.filter(item => {
      const matchCat = activeCat === 'all' || item.cat === activeCat;
      const matchText = !q || item.name.toLowerCase().includes(q) || item.ext.toLowerCase().includes(q);
      return matchCat && matchText;
    });

    if (matches.length === 0) {
      grid.innerHTML = `
        <div style="grid-column: 1 / -1; padding: 32px 16px; text-align: center; color: var(--text-muted); font-size: 13px;">
          No matching formats found. You can add any custom extension (e.g. .svelte, .proto) directly in MacNewFile Settings.
        </div>
      `;
      return;
    }

    grid.innerHTML = matches.map(item => `
      <div class="catalog-item">
        <div>
          <div class="item-name">${item.name}</div>
          <div class="item-ext">${item.ext}</div>
        </div>
        <span class="item-badge">${item.type}</span>
      </div>
    `).join('');
  };

  renderGrid();

  if (searchInput) {
    searchInput.addEventListener('input', renderGrid);
  }

  filterPills.forEach(pill => {
    pill.addEventListener('click', () => {
      filterPills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      activeCat = pill.getAttribute('data-cat') || 'all';
      renderGrid();
    });
  });

  // 6. Terminal Selector Showcase
  const termBtns = document.querySelectorAll('.terminal-tab-btn');
  const termHeader = document.getElementById('termHeaderLabel');
  const termOutput = document.getElementById('termCommandOutput');

  const terms = {
    'ghostty': { label: 'Ghostty — zsh (Native Metal)', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Ghostty .' },
    'iterm': { label: 'iTerm2 — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a iTerm .' },
    'terminal': { label: 'Terminal.app — zsh (Default)', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Terminal .' },
    'warp': { label: 'Warp — zsh', cmd: 'cd ~/Developer/MacNewFile-Enhanced && open -a Warp .' },
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

  // 7. Installation Tabs
  const installTriggers = document.querySelectorAll('.install-tab-trigger');
  const installPanels = document.querySelectorAll('.install-panel-box');

  installTriggers.forEach(trigger => {
    trigger.addEventListener('click', () => {
      installTriggers.forEach(t => t.classList.remove('active'));
      installPanels.forEach(p => p.style.display = 'none');
      trigger.classList.add('active');
      const targetId = trigger.getAttribute('data-tab');
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.style.display = 'block';
    });
  });

  // 8. FAQ Accordion (Smooth & Accessible)
  document.querySelectorAll('.faq-trigger').forEach(trigger => {
    trigger.addEventListener('click', () => {
      const card = trigger.closest('.faq-card');
      if (!card) return;
      const isOpen = card.classList.contains('open');
      
      // Close all other cards for clean accordion behavior
      document.querySelectorAll('.faq-card').forEach(c => {
        if (c !== card) {
          c.classList.remove('open');
          c.querySelector('.faq-trigger')?.setAttribute('aria-expanded', 'false');
        }
      });

      card.classList.toggle('open', !isOpen);
      trigger.setAttribute('aria-expanded', !isOpen);
    });
  });
});
