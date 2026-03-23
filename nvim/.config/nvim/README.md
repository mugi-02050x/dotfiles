# kickstart.nvim

## Introduction
Welcome to the customized Neovim configuration! This project is a fork of the kickstart.nvim configuration, customized for personal use.

## Installation
### Install kickstart.nvim
```sh
git clone git@github.com:mugi-02050x/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/kickstart.nvim
export SHELL_PROFILE="$HOME/.bashrc"
## export SHELL_PROFILE="$HOME/.bash_profile"
## export SHELL_PROFILE="$HOME/.zshhrc"
## export SHELL_PROFILE="$HOME/.zsh_profile"
echo "alias kvim='env NVIM_APPNAME=kickstart.nvim nvim'" >> SHELL_PROFILE
source $SHELL_PROFILE
```

### Post Installation
Start kickstart.nvim
```sh
kvim
```

### Settings of Java Language Server 
Modify the TODO in the following file to suit your environment.
```
kvim ${XDG_CONFIG_HOME:-$HOME/.config}"/kickstart.nvim/ftplugin/java.lua"
```

## References
- [Videos used as reference when setting up](https://www.youtube.com/watch?v=C7juSZsM2Fg)
