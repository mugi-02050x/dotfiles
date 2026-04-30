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
for _p in "${_pm_prefixes[@]}"; do
  [[ -d "$_p/bin" ]]  && PATH="$_p/bin:$PATH"
  [[ -d "$_p/sbin" ]] && PATH="$_p/sbin:$PATH"
done

# FHS 標準パス（pm_prefix とは独立、手動インストール先）
[[ -d /usr/local/bin ]]  && PATH="/usr/local/bin:$PATH"
[[ -d /usr/local/sbin ]] && PATH="/usr/local/sbin:$PATH"

# ユーザー単位ローカルバイナリ（pipx、pip --user、cargo install など / XDG 慣習）
[[ -d "$HOME/.local/bin" ]]                                        && PATH="$HOME/.local/bin:$PATH"
# nodebrew が選択中の Node.js バージョン（node, npm, グローバルインストール CLI）
[[ -d "$HOME/.nodebrew/current/bin" ]]                             && PATH="$HOME/.nodebrew/current/bin:$PATH"
[[ -d "$HOME/.nodebrew/current/sbin" ]]                            && PATH="$HOME/.nodebrew/current/sbin:$PATH"
# VMware Fusion の CLI ツール（vmrun、ovftool など）
[[ -d "/Applications/VMware Fusion.app/Contents/Public" ]]         && PATH="/Applications/VMware Fusion.app/Contents/Public:$PATH"

export PATH

# --- JAVA_HOME 解決 ---
# 検出結果を一旦この変数に格納し、最終的に export する流れ
_java_home=""

# 第一優先: macOS の java_home ヘルパー（システム登録された全 JDK を横断検索）
if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home -v 25 2>/dev/null)"
fi

# 第二優先: Linux 標準の JVM 配置先（Debian/Ubuntu の openjdk-25-jdk パッケージ）
if [[ -z "$_java_home" ]]; then
  for _candidate in \
    /usr/lib/jvm/java-25-openjdk-amd64 \
    /usr/lib/jvm/java-25-openjdk-arm64 \
    /usr/lib/jvm/default-java; do
    if [[ -d "$_candidate" ]]; then
      _java_home="$_candidate"
      break
    fi
  done
  unset _candidate
fi

# 第三優先: Homebrew / Linuxbrew で導入した openjdk@25 formula を直接探索
# (java_home に登録されない formula 配置の JDK を拾うためのフォールバック)
if [[ -z "$_java_home" ]]; then
  for _p in "${_pm_prefixes[@]:-}"; do
    # macOS Homebrew 形式（Contents/Home 階層あり）
    if [[ -d "$_p/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
      _java_home="$_p/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
      break
    fi
    # Linuxbrew 形式（Contents/Home 階層なし）
    if [[ -d "$_p/opt/openjdk@25/libexec" ]]; then
      _java_home="$_p/opt/openjdk@25/libexec"
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
