#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this script is for macOS only" >&2
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Complete the GUI dialog, then press Enter to continue..."
  read -r
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# パッケージ一括導入
echo "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# Node.js（nodebrew で最新版を導入）
if ! command -v node &>/dev/null; then
  echo "Installing Node.js via nodebrew..."
  nodebrew setup 2>/dev/null || true
  nodebrew install-binary latest
  _latest_node="$(find "$HOME/.nodebrew/node" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -V | tail -1)"
  if [[ -n "${_latest_node:-}" ]]; then
    nodebrew use "$_latest_node"
  fi
  unset _latest_node
  export PATH="$HOME/.nodebrew/current/bin:$PATH"
fi

# グローバル npm パッケージ（追加はこの配列に行を増やす）
NPM_GLOBALS=(
  "@google/gemini-cli"  # tmux <prefix>G
  "basedpyright"        # Python LSP / type checker
  "obsidian-headless"   # Obsidian 自動化 CLI
)
if command -v npm &>/dev/null && [[ ${#NPM_GLOBALS[@]} -gt 0 ]]; then
  echo "Installing global npm packages..."
  npm install -g "${NPM_GLOBALS[@]}"
  _npm_global_root="$(npm root -g)"
  _better_sqlite3_dir="$_npm_global_root/obsidian-headless/node_modules/better-sqlite3"
  if [[ -d "$_better_sqlite3_dir" ]]; then
    echo "Rebuilding obsidian-headless native dependencies..."
    (cd "$_better_sqlite3_dir" && npm rebuild --ignore-scripts=false)
  fi
  unset _npm_global_root _better_sqlite3_dir
fi

# Codex CLI は remote-control/app-server daemon が standalone layout を前提にするため、
# npm global ではなく公式 standalone installer で導入する。
if command -v npm &>/dev/null && npm list -g @openai/codex --depth=0 &>/dev/null; then
  echo "Removing npm-managed Codex CLI..."
  npm uninstall -g @openai/codex
fi

echo "Installing Codex CLI standalone..."
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

# symlink 配置
echo "Linking dotfiles..."
"$DOTFILES_DIR/install.sh"

echo "Done. Restart your shell or run: exec zsh -l"
