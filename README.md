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
| bin | `~/.local/bin/` |

### Brewfile へのパッケージ追加

`Brewfile` を編集して `brew bundle` を再実行すると差分のみインストールされます。

```bash
echo 'brew "ripgrep"' >> Brewfile
brew bundle
```

## エージェント利用率の表示

`agent-usage` は Claude Code と Codex のレート制限（5時間枠・週枠）の利用率を表示するビューアです。
tmux では `Prefix + u` でポップアップ表示できます（`r` で再取得、`q` で閉じる）。

起動時に Claude（Keychain の OAuth トークン経由の usage API）と Codex（`codex app-server` への JSON-RPC）から
利用率を取得し、`~/.cache/agent-usage/state.json` を更新して表示します。デーモンは常駐せず、
前回取得から55秒未満の場合はキャッシュを再利用します。

### エージェントの有効/無効設定

`~/.config/agent-usage/config.json`（任意）でエージェントごとに取得・表示を制御できます。
ファイルがない場合、および記載のないエージェントはすべて有効です。

```json
{
  "agents": {
    "codex": {"enabled": false}
  }
}
```

`enabled: false` にしたエージェントは取得処理自体が実行されません。
新しいエージェントの追加手順はスクリプト先頭の docstring を参照してください。

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
