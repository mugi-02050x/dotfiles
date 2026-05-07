# dotfiles

GNU Stow で管理する個人の dotfiles リポジトリ。

## セットアップ

```bash
# 前提: GNU Stow がインストール済み (例: brew install stow)

git clone git@github.com:mugi-02050x/dotfiles.git
cd dotfiles
./install.sh
```

> **注意**: stow 実行前に既存の設定ファイルをバックアップしてください。
> ```bash
> mv ~/.zshrc ~/.zshrc.bak
> mv ~/.config/nvim ~/.config/nvim.bak
> mv ~/.tmux.conf ~/.tmux.conf.bak
> ```

## 構成

| パッケージ | リンク先 |
|---|---|
| zsh | `~/.zshrc` |
| nvim | `~/.config/nvim/` |
| tmux | `~/.tmux.conf` |
| bin | `~/.local/bin/` |

## SSH元クリップボードへのコピー

SSH接続中は `clip` コマンドがOSC 52を使ってSSHクライアント側のクリップボードへコピーします。

```bash
echo "copy me" | clip
clip "copy me"
```

tmuxのコピーモードでは `y` / `Enter` で `clip` に渡します。NeovimはSSH接続中のみ `"+y` や通常のyankを `clip` 経由にします。

Windows TerminalなどOSC 52対応のSSHクライアントで動作します。AndroidのSSHクライアントはOSC 52対応状況に依存します。
