# Neovim 設定

`lazy.nvim` で管理している個人用 Neovim 設定。

## 構成

```text
.
|-- init.lua
|-- lazy-lock.json
|-- ftplugin/
|   |-- java.lua
|   `-- python.lua
`-- lua/
    |-- config/
    |   |-- autocmds.lua
    |   |-- keymaps.lua
    |   `-- options.lua
    `-- plugins/
        |-- completion.lua
        |-- debugging.lua
        |-- formatting.lua
        |-- gitsigns.lua
        |-- lsp.lua
        |-- neo-tree.lua
        |-- telescope.lua
        |-- tools.lua
        |-- treesitter.lua
        |-- ui.lua
        `-- which-key.lua
```

`init.lua` で leader key を設定し、`lua/config` の基本設定を読み込んだ後、
`lazy.nvim` を bootstrap して `lua/plugins` 配下の plugin spec を import する。

## 基本設定

- Leader key は `<Space>`。
- Nerd Font の利用を前提に `vim.g.have_nerd_font = true`。
- 行番号と相対行番号を有効化。
- ローカル環境では clipboard に `unnamedplus` を利用。
- SSH 接続中は `clip` コマンドを使い、OSC 52 で接続元 clipboard へ yank をミラーする。
- diagnostic は severity 順に並べ、virtual text を表示する。
- Neovim 外で変更されたファイルは自動 reload する。

## 基本キーマップ

| Key | Mode | Action |
|---|---|---|
| `;` | normal | command-line mode |
| `:` | normal | `f` / `t` motion の repeat |
| `<Esc>` | normal | 検索 highlight を消す |
| `<leader>q` | normal | diagnostic quickfix list を開く |
| `<Esc><Esc>` | terminal | terminal mode を抜ける |
| `jj` | insert | insert mode を抜ける |

## 導入プラグイン

### Plugin Manager

- `folke/lazy.nvim`

### UI

- `folke/tokyonight.nvim`: colorscheme
- `nvim-mini/mini.nvim`: `mini.ai`, `mini.surround`, `mini.statusline`
- `folke/todo-comments.nvim`: TODO/FIXME などの highlight
- `folke/which-key.nvim`: keymap hint
- `nvim-tree/nvim-web-devicons`: file icon / UI icon

#### mini.ai

`mini.ai` は textobject を拡張する。`d`, `c`, `y`, `v` などの operator と
`a` / `i` textobject を組み合わせて使う。

| Key | Action |
|---|---|
| `ci"` | `"` の内側を変更 |
| `da)` | `()` ごと削除 |
| `vif` | function の内側を選択 |
| `vaf` | function 全体を選択 |
| `via` | argument の内側を選択 |
| `vaa` | argument 全体を選択 |

`a` は around、`i` は inside。標準の `iw` / `i"` / `i)` の対象を、
function や argument などにも広げる用途で使う。

#### mini.surround

`mini.surround` は括弧、quote、tag などの囲み文字を追加、削除、置換する。

| Key | Action |
|---|---|
| `saiw"` | cursor 上の word を `"` で囲む |
| `saiw)` | cursor 上の word を `()` で囲む |
| `saip}` | paragraph を `{}` で囲む |
| `sd"` | cursor 周辺の `"` を削除 |
| `sd)` | cursor 周辺の `()` を削除 |
| `sr"'` | `"` を `'` に置換 |
| `sr)]` | `()` を `[]` に置換 |

まずは `saiw"`、`sd"`、`sr"'` を覚えると使い始めやすい。

### Completion

- `saghen/blink.cmp`: 補完 engine
- `L3MON4D3/LuaSnip`: snippet engine

補完 source は LSP、path、snippet。

### LSP

- `neovim/nvim-lspconfig`
- `mason-org/mason.nvim`
- `mason-org/mason-lspconfig.nvim`
- `WhoIsSethDaniel/mason-tool-installer.nvim`
- `j-hui/fidget.nvim`
- `mfussenegger/nvim-jdtls`

有効化している language server:

- `clangd`
- `basedpyright`
- `ts_ls`
- `lua_ls`

Java は `mason-lspconfig` の自動 enable から除外し、`ftplugin/java.lua` で
`nvim-jdtls` を個別に起動する。

### Formatting

- `stevearc/conform.nvim`

設定している formatter:

| Filetype | Formatter |
|---|---|
| Lua | `stylua` |
| Python | `ruff_format` |
| JavaScript | `prettierd` |
| JavaScript React | `prettierd` |
| TypeScript | `prettierd` |
| TypeScript React | `prettierd` |
| Java | `jdtls` |

C / C++ 以外は保存時 format を有効化している。

### Treesitter

- `nvim-treesitter/nvim-treesitter`

install 対象 parser:

- `bash`
- `c`
- `diff`
- `html`
- `lua`
- `luadoc`
- `markdown`
- `markdown_inline`
- `query`
- `vim`
- `vimdoc`
- `java`

### Search

- `nvim-telescope/telescope.nvim`
- `nvim-lua/plenary.nvim`
- `nvim-telescope/telescope-fzf-native.nvim`
- `nvim-telescope/telescope-ui-select.nvim`

主な Telescope mapping:

| Key | Action |
|---|---|
| `<leader>sf` | find files |
| `<leader>sg` | live grep |
| `<leader>sw` | grep current word |
| `<leader>sd` | diagnostics |
| `<leader>sk` | keymaps |
| `<leader>sh` | help tags |
| `<leader>sc` | commands |
| `<leader><leader>` | buffers |
| `<leader>/` | current buffer fuzzy search |
| `<leader>sn` | Neovim 設定ファイル検索 |

`find_files` と `live_grep` は hidden file と gitignored file も対象にする。

### File Tree

- `nvim-neo-tree/neo-tree.nvim`
- `MunifTanjim/nui.nvim`

| Key | Action |
|---|---|
| `//` | 現在の file を Neo-tree で reveal |

dotfiles と gitignored files は表示する。`.git`, `.DS_Store`, `.history` は表示しない。

### Git

- `lewis6991/gitsigns.nvim`

追加、変更、削除の sign を表示する。

### Debugging

- `mfussenegger/nvim-dap`
- `rcarriga/nvim-dap-ui`
- `theHamsta/nvim-dap-virtual-text`
- `nvim-neotest/nvim-nio`
- `nvim-telescope/telescope-dap.nvim`

主な debug mapping:

| Key | Action |
|---|---|
| `<leader>bb` | toggle breakpoint |
| `<leader>bc` | conditional breakpoint |
| `<leader>bl` | logpoint |
| `<leader>br` | clear breakpoints |
| `<leader>ba` | list breakpoints |
| `<leader>dc` / `<F8>` | continue |
| `<leader>dj` / `<F6>` | step over |
| `<leader>dk` / `<F5>` | step into |
| `<leader>do` / `<F7>` | step out |
| `<leader>dl` / `<F11>` | run last |
| `<leader>dd` | disconnect |
| `<leader>dt` | terminate |
| `<leader>dr` | toggle REPL |
| `<leader>df` | debug frames |
| `<leader>dh` | debug commands |

Java の debug configuration は JDTLS の main class discovery から生成する。

### Tools

- `NMAC427/guess-indent.nvim`: indent 自動判定
- `christoomey/vim-tmux-navigator`: Vim window / tmux pane 間の移動
- `iamcco/markdown-preview.nvim`: Markdown preview
- `barrett-ruth/live-server.nvim`: HTML/CSS/JavaScript 用 live server

主な tool mapping:

| Key | Action |
|---|---|
| `<C-h>` | 左の Vim/tmux pane へ移動 |
| `<C-j>` | 下の Vim/tmux pane へ移動 |
| `<C-k>` | 上の Vim/tmux pane へ移動 |
| `<C-l>` | 右の Vim/tmux pane へ移動 |
| `<C-\>` | 前の Vim/tmux pane へ移動 |
| `<leader>mp` | Markdown preview toggle |
| `<leader>ls` | live server start |
| `<leader>lx` | live server stop |

## Filetype 固有設定

### Java

`ftplugin/java.lua` で `nvim-jdtls` を設定する。

- Neovim data directory 配下に JDTLS workspace を作成。
- Lombok を有効化。
- Java debug adapter bundle を読み込む。
- JDTLS には JDK 21 を使う。
- Java 17 / 21 / 25 runtime を登録。
- Maven source download を有効化。
- organize imports と extract refactor 用 mapping を定義。

Java refactor mapping:

| Key | Mode | Action |
|---|---|---|
| `<leader>co` | normal | organize imports |
| `<leader>crv` | normal/visual | extract variable |
| `<leader>crc` | normal/visual | extract constant |
| `<leader>crm` | visual | extract method |

### Python

`ftplugin/python.lua` で `<F5>` を現在の Python file 実行に割り当てる。
実行時は terminal split を開く。

## Lockfile

`lazy-lock.json` で plugin revision を固定している。
plugin を意図的に更新した場合は、この lockfile も commit する。
