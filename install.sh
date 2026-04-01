#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DOTFILES_DIR"
stow --target="$HOME" zsh
stow --target="$HOME" nvim
stow --target="$HOME" tmux

echo "Done!"
