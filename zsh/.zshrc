# --- パッケージマネージャー prefix の検出 ---
typeset -a _pm_prefixes

if command -v brew &>/dev/null; then
  _pm_prefixes+=("$(brew --prefix)")
elif [[ -x /opt/homebrew/bin/brew ]]; then
  _pm_prefixes+=("/opt/homebrew")
elif [[ -x /usr/local/bin/brew ]]; then
  _pm_prefixes+=("/usr/local")
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  _pm_prefixes+=("/home/linuxbrew/.linuxbrew")
fi

[[ -d /opt/local ]] && _pm_prefixes+=("/opt/local")
[[ -d "$HOME/.nix-profile" ]] && _pm_prefixes+=("$HOME/.nix-profile")
[[ -d /nix/var/nix/profiles/default ]] && _pm_prefixes+=("/nix/var/nix/profiles/default")

# --- PATH 構築 ---
for _p in "${_pm_prefixes[@]}"; do
  [[ -d "$_p/bin" ]]  && PATH="$_p/bin:$PATH"
  [[ -d "$_p/sbin" ]] && PATH="$_p/sbin:$PATH"
done

[[ -d "$HOME/.local/bin" ]]                                        && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.nodebrew/current/bin" ]]                             && PATH="$HOME/.nodebrew/current/bin:$PATH"
[[ -d "$HOME/.nodebrew/current/sbin" ]]                            && PATH="$HOME/.nodebrew/current/sbin:$PATH"
[[ -d "/Applications/VMware Fusion.app/Contents/Public" ]]         && PATH="/Applications/VMware Fusion.app/Contents/Public:$PATH"

export PATH

# --- JAVA_HOME 解決 ---
_java_home=""
if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home -v 25 2>/dev/null)"
fi
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
