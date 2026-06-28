# Third-Party Notices

## tokyonight.nvim

- Project: `folke/tokyonight.nvim`
- Source: <https://github.com/folke/tokyonight.nvim>
- Vendored file: `tmux/.config/tmux/themes/tokyonight_night.tmux`
- Upstream source path: `extras/tmux/tokyonight_night.tmux`
- License: Apache License 2.0
- License copy: `LICENSES/tokyonight.nvim/LICENSE`

The vendored tmux theme is copied from `folke/tokyonight.nvim` and kept as a
local dotfiles asset so tmux can load it through GNU Stow. Local tmux settings
may override selected status-line formats after this theme is sourced.

## tmux-claude-session-manager

- Project: `craftzdog/tmux-claude-session-manager`
- Source: <https://github.com/craftzdog/tmux-claude-session-manager>
- License: MIT

The `agent-session` workflow in this repository is inspired by the session
management concept of `tmux-claude-session-manager`, but is implemented
independently for this dotfiles setup. No source code from
`tmux-claude-session-manager` is vendored in this repository.
