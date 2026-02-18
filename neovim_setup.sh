#!/bin/bash

set -e

CONFIG_DIR="$HOME/.config/nvim"
INIT_FILE="$CONFIG_DIR/init.lua"
PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"

echo "Starte Neovim-Einrichtung..."

sudo apt install nvim git clang-format black

# 1. Neovim Konfigurationsverzeichnis erstellen
mkdir -p "$CONFIG_DIR"

# 2. init.lua schreiben
cat > "$INIT_FILE" << 'EOF'
-- init.lua für Neovim (ab Version 0.5+)

-- =========================
-- Grundlegende Einstellungen
-- =========================
vim.o.number = true           -- Zeilennummern anzeigen
vim.o.relativenumber = true   -- relative Zeilennummern für einfaches Navigieren
vim.o.expandtab = true        -- Tabs durch Spaces ersetzen
vim.o.shiftwidth = 4          -- 4 Spaces pro Tab
vim.o.tabstop = 4
vim.o.smartindent = true      -- automatische Einrückung
vim.o.termguicolors = true    -- bessere Farben

-- Einfaches Farbschema (kann angepasst werden)
vim.cmd('colorscheme desert')

-- =========================
-- Plugin-Manager: packer.nvim
-- =========================
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Packer selbst

  -- Syntax Highlighting & Code-Struktur mit Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  -- Autocompletion & LSP (Language Server Protocol) für C, Python etc.
  use {'neoclide/coc.nvim', branch = 'release'}

  -- Code-Formatter (clang-format für C, black für Python)
  use 'mhartington/formatter.nvim'

  -- Unterstützung für Makefiles (wichtig für Embedded Projekte)
  use 'tpope/vim-dispatch'

  -- Terminal-Integration & SSH Navigation (praktisch für Raspberry Pi & Server)
  use 'christoomey/vim-tmux-navigator'

  -- Git Integration (Versionskontrolle)
  use 'tpope/vim-fugitive'
end)

-- =========================
-- Treesitter konfigurieren
-- =========================
pcall(function()
  require'nvim-treesitter.configs'.setup {
    ensure_installed = {"c", "python", "lua", "make"},
    highlight = { enable = true },
    indent = { enable = true },
  }
end)

-- =========================
-- Formatter konfigurieren
-- =========================
require('formatter').setup({
  logging = false,
  filetype = {
    c = {
      function() return {exe = "clang-format", args = {"-style=Google"}, stdin = true} end
    },
    python = {
      function() return {exe = "black", args = {"-"}, stdin = true} end
    }
  }
})

-- Einfacher Befehl zum Formatieren: :Format

-- =========================
-- Coc.nvim (LSP & Autocompletion) Grundsetup
-- =========================
-- Autovervollständigung mit Ctrl+Space
vim.cmd([[
  inoremap <silent><expr> <C-Space> coc#refresh()
]])

-- =========================
-- Nützliche Tastenkürzel (Mappings) für Schüler
-- =========================
-- Speichern mit Ctrl+s
vim.api.nvim_set_keymap('n', '<C-s>', ':w<CR>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-s>', '<Esc>:w<CR>a', { noremap = true })

-- Formatieren mit F3
vim.api.nvim_set_keymap('n', '<F3>', ':Format<CR>', { noremap = true })
EOF

echo "init.lua wurde erstellt."

# 3. packer.nvim installieren, falls nicht vorhanden
if [ ! -d "$PACKER_DIR" ]; then
  echo "packer.nvim wird installiert..."
  git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR"
else
  echo "packer.nvim ist bereits installiert."
fi

# 4. Plugins installieren via packer
echo "Plugins werden installiert/aktualisiert..."
nvim --headless +PackerSync +qall

# 5. Coc.nvim Extensions installieren
echo "Installiere Coc.nvim Language Server..."
nvim --headless +'CocInstall -sync coc-clangd coc-pyright' +qall

# 6. Treesitter Parser aktualisieren
echo "Aktualisiere Treesitter Parser..."
nvim --headless +TSUpdate +qall

echo "Neovim-Konfiguration und Plugins wurden vollständig eingerichtet."

echo "Du kannst jetzt Neovim starten und sofort mit dem Programmieren beginnen! 🚀"
