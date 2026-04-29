# dotfiles

GNU Stow で管理する個人の dotfiles リポジトリ。

## セットアップ

### 新品 Mac（Homebrew 未導入）

```bash
git clone git@github.com:mugi-02050x/dotfiles.git
cd dotfiles
./setup-mac.sh
```

Xcode Command Line Tools と Homebrew が未導入の場合は自動でインストールします。
その後 `Brewfile` に記載されたパッケージを一括導入し、symlink を配置します。

### 既存環境（Homebrew 導入済み）

```bash
git clone git@github.com:mugi-02050x/dotfiles.git
cd dotfiles
brew bundle
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

### Brewfile へのパッケージ追加

`Brewfile` を編集して `brew bundle` を再実行すると差分のみインストールされます。

```bash
echo 'brew "ripgrep"' >> Brewfile
brew bundle
```
