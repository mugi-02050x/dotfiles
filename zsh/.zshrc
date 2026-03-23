export PATH="PATH:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/VMware Fusion.app/Contents/Public:$HOME/.nodebrew/current/bin:$HOME/.nodebrew/current/sbin :$JAVA_HOME/bin"\:/Library/Frameworks/Python.framework/Versions/3.10/bin
# export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk
alias python="python3" 
alias pip="pip3"
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/nakamurashouta/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

export JAVA_HOME=$(/opt/homebrew/bin/brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
alias kvim='env NVIM_APPNAME=kickstart.nvim nvim'
alias nvchad='env NVIM_APPNAME=nvchad nvim'
alias vi='nvim'
alias view='nvim -R'
