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

tmuxのコピーモードでは `y` / `Enter` で `clip` に渡します。NeovimはSSH接続中のみ通常のyankを内部レジスタに残したまま `clip` へミラーし、`"+y` も `clip` 経由にします。

Windows TerminalなどOSC 52対応のSSHクライアントで動作します。AndroidのSSHクライアントはOSC 52対応状況に依存します。

## SSH接続時の改行入力

agent系TUIの複数行入力では、通常の `Enter` は送信、`Shift+Enter` は改行として扱われることがあります。
tmux上でも `Shift+Enter` をアプリへ渡すため、`~/.tmux.conf` では `extended-keys always` と `xterm*` / `tmux*` の `extkeys` を有効にしています。

設定変更後は既存tmuxサーバーに反映してください。

```bash
tmux source-file ~/.tmux.conf
tmux show-options -g extended-keys
tmux show-options -g terminal-features
```

`extended-keys always` が表示されていればtmux側の設定は有効です。
それでも `Shift+Enter` が改行にならない場合は、SSHクライアントまたは端末アプリが `Shift+Enter` を通常の `Enter` と同じコードで送っている可能性があります。

切り分けにはtmuxの外と中で次を実行し、`Shift+Enter` が `^[[13;2u` のような通常の改行とは異なるシーケンスになるか確認します。

```bash
cat -v
```

`Enter` と `Shift+Enter` がどちらも単なる改行として表示される場合、このdotfiles側では区別できないため、接続元のターミナル設定やSSHクライアントを変更してください。
