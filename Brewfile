# --- Core: dotfile 管理 ---
brew "stow"

# --- Editor / Terminal multiplexer ---
brew "neovim"
brew "tmux"

# --- 言語ランタイム / バージョン管理 ---
brew "openjdk@25"
brew "nodebrew"

# --- Git ツールチェーン ---
brew "git"
brew "gh"
brew "lazygit"          # tmux <prefix>g

# --- AI CLI（tmux ポップアップから呼ぶ）---
brew "gemini-cli"       # tmux <prefix>G

# --- nvim プラグインビルド依存 ---
brew "make"
brew "cmake"
brew "gcc"
brew "tree-sitter"
brew "tree-sitter-cli"
brew "ripgrep"          # telescope live_grep

# --- Mason がダウンロードに使う ---
brew "curl"
brew "wget"
brew "unzip"

# --- Python ツール ---
brew "uv"
brew "ruff"
brew "basedpyright"

# --- 開発便利ツール ---
brew "fzf"
brew "jq"
brew "tree"
brew "shellcheck"       # Claude Code の自動フォーマットフックが使用

# --- macOS 専用（cask は Homebrew 上で macOS 限定。Linux では別途 apt 等で導入する） ---
cask "docker-desktop"                 # tmux でアプリ完結（旧 cask "docker" は非推奨）
cask "claude-code"                    # tmux <prefix>a
cask "font-jetbrains-mono-nerd-font"  # 接続元ターミナルのフォント（Ubuntu Server へも反映）
