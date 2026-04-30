# --- パッケージマネージャー prefix の検出 ---
typeset -a _pm_prefixes

if command -v brew &>/dev/null; then
  # Homebrew: PATH 上で見つかる場合は brew --prefix を信頼（カスタム配置や Linuxbrew にも対応）
  _pm_prefixes+=("$(brew --prefix)")
elif [[ -x /opt/homebrew/bin/brew ]]; then
  # Homebrew: Apple Silicon Mac の標準インストール先
  _pm_prefixes+=("/opt/homebrew")
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  # Homebrew: Linux 版（Linuxbrew）の標準インストール先
  _pm_prefixes+=("/home/linuxbrew/.linuxbrew")
fi

# MacPorts: macOS 向けの別系統パッケージマネージャー、prefix は固定
[[ -d /opt/local ]] && _pm_prefixes+=("/opt/local")
# Nix: ユーザー単位プロファイル（single-user / per-user インストール時）
[[ -d "$HOME/.nix-profile" ]] && _pm_prefixes+=("$HOME/.nix-profile")
# Nix: システム共通プロファイル（multi-user インストール時のデフォルト）
[[ -d /nix/var/nix/profiles/default ]] && _pm_prefixes+=("/nix/var/nix/profiles/default")

# --- PATH 構築 ---
# 「先頭追加」方式: 低優先のものから順に追加する（後から追加したものほど PATH 先頭=高優先になる）
# 最終的な優先順位（高い順）:
#   JAVA_HOME → nodebrew → Homebrew(pm_prefixes) → ~/.local/bin → /usr/local → VMware → 元の PATH

# VMware Fusion の CLI ツール（vmrun、ovftool など）— 使用頻度が低く名前衝突もないので最下位
[[ -d "/Applications/VMware Fusion.app/Contents/Public" ]]         && PATH="/Applications/VMware Fusion.app/Contents/Public:$PATH"

# FHS 標準パス（pm_prefix とは独立、手動インストール先）
[[ -d /usr/local/bin ]]  && PATH="/usr/local/bin:$PATH"
[[ -d /usr/local/sbin ]] && PATH="/usr/local/sbin:$PATH"

# ユーザー単位ローカルバイナリ（pipx、pip --user、cargo install など / XDG 慣習）
[[ -d "$HOME/.local/bin" ]]                                        && PATH="$HOME/.local/bin:$PATH"

# パッケージマネージャ（Homebrew 等）— 同名コマンドがあれば手動インストールより優先したい
for _p in "${_pm_prefixes[@]}"; do
  [[ -d "$_p/bin" ]]  && PATH="$_p/bin:$PATH"
  [[ -d "$_p/sbin" ]] && PATH="$_p/sbin:$PATH"
done

# nodebrew が選択中の Node.js バージョン（node, npm, グローバルインストール CLI）
# Homebrew 版 node より優先したいので Homebrew より後に追加
[[ -d "$HOME/.nodebrew/current/bin" ]]                             && PATH="$HOME/.nodebrew/current/bin:$PATH"
[[ -d "$HOME/.nodebrew/current/sbin" ]]                            && PATH="$HOME/.nodebrew/current/sbin:$PATH"

export PATH

# --- JAVA_HOME 解決 ---
# 検出結果を一旦この変数に格納し、最終的に export する流れ
_java_home=""

# 第一優先: macOS 標準の java_home ヘルパー経由（Oracle JDK / Zulu / Temurin など
# システムに登録されたあらゆる JDK を横断検索できる。-v 25 で JDK 25 を要求）
if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home -v 25 2>/dev/null)"
fi

# 第二優先: Homebrew / Linuxbrew 等で導入した openjdk@25 を直接探索
# (java_home に登録されない formula 配置の JDK を拾うためのフォールバック)
if [[ -z "$_java_home" ]]; then
  for _p in "${_pm_prefixes[@]:-}"; do
    if [[ -d "$_p/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
      _java_home="$_p/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
      break
    fi
  done
fi
if [[ -n "$_java_home" ]]; then
  export JAVA_HOME="$_java_home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
unset _p _pm_prefixes _java_home

# --- エイリアス ---
alias python="python3"
alias pip="pip3"
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
