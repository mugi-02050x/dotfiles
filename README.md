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
> ```

## 構成

| パッケージ | リンク先 |
|---|---|
| zsh | `~/.zshrc` |
| nvim | `~/.config/nvim/` |
