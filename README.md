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
| bin | `~/.local/bin/`, `~/.local/lib/` |
| lazysql | `~/.config/lazysql/` |

### Brewfile へのパッケージ追加

`Brewfile` を編集して `brew bundle` を再実行すると差分のみインストールされます。

```bash
echo 'brew "ripgrep"' >> Brewfile
brew bundle
```

## ターミナル内SQLクライアント

`lazysql` は MySQL / PostgreSQL / SQLite / MSSQL に対応したTUIデータベースクライアントです。
tmux では `Prefix + q` でセッション維持型ポップアップとして起動します。

接続設定は `~/.config/lazysql/config.toml` に保存されます。このリポジトリでは
`lazysql/.config/lazysql/config.toml.example` だけを管理し、実際の `config.toml` は `.gitignore` で除外します。

```bash
cp ~/.config/lazysql/config.toml.example ~/.config/lazysql/config.toml
$EDITOR ~/.config/lazysql/config.toml
```

パスワードなどの秘密情報は、`config.toml` に直書きせず `${env:VAR_NAME}` 形式で環境変数から参照してください。

基本操作:
- `n`: 接続を追加
- `c` / `Enter`: 接続
- `j` / `k`: 移動
- `[` / `]`: テーブル表示タブの切り替え
- `Ctrl+E`: SQLエディタを開く
- `Ctrl+R`: SQLを実行
- `?`: ヘルプ

## ターミナル内 Docker クライアント

`lazydocker` は Docker / Docker Compose のコンテナ・イメージ・ネットワーク・ボリュームを TUI で操作できるツールです。
tmux では `Prefix + k` でセッション維持型ポップアップとして起動します。

設定は `~/.config/jesseduffield/lazydocker/config.yml` に保存されますが、本リポジトリではデフォルト設定のままで運用するため管理しません。

基本操作:
- `j` / `k`: 移動
- `[` / `]`: パネル切り替え
- `Enter`: 詳細表示
- `d`: 停止コンテナの削除
- `r`: リスタート
- `?`: ヘルプ

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

## AIエージェントのターン完了通知

`agent-notify` は Claude Code / Codex のターン完了・承認待ちを `terminal-notifier` でデスクトップ通知します。
複数セッションを並行で動かしてもプロジェクト名で見分けられ、通知をクリックすると該当の tmux ペインへ復帰します。

- タイトルに `<agent> ▸ <cwd の basename>`、サブタイトルに状態（ターン完了 / 承認待ち / 入力待ち）、本文に発話プレビュー
- `-group "<agent>-<TMUX_PANE>"` で連続通知を最新 1 件に集約
- クリック時は terminal-notifier の `-activate` で iTerm を前面化し、`-execute` で `tmux-focus-pane-hook` を呼んで該当ペインへ復帰

クリック復帰（`tmux-focus-pane-hook`）はペインの所属セッションで挙動を分けます。

- 通常のウィンドウ/ペイン: `switch-client` / `select-window` / `select-pane` で移動
- セッション維持型ポップアップ（`prefix + A` 等で起動した `<agent>-<hash>` セッション）: メインクライアントを直接アタッチさせると（`switch-client`）デタッチ時に tmux を抜けてしまうため行わず、ポップアップが閉じていればメインクライアント上で `display-popup` を開き直す。デタッチすると元のセッションへ戻る

前提として `terminal-notifier`（Brewfile に記載）が必要です。未導入時や tmux 外では iTerm の前面化のみにフォールバックします。

### Claude Code

`~/.claude/settings.json` の `hooks` で Stop / Notification から呼びます。

```json
{
  "hooks": {
    "Stop": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-notify claude-stop" }
      ] }
    ],
    "Notification": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-notify claude-notification" }
      ] }
    ]
  }
}
```

### Codex

`~/.codex/hooks.json` の `PermissionRequest` / `Stop` フックで呼びます。
承認待ちとターン完了を別イベントとして受け取るため、状態ごとに通知音を切り替えられます。

```json
{
  "hooks": {
    "PermissionRequest": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-notify codex-notification" }
      ] }
    ],
    "Stop": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-notify codex-stop" }
      ] }
    ]
  }
}
```

設定後は Codex を再起動し、`/hooks` で追加したフックを確認・信頼してください。
同じイベントに複数のフックを設定できるため、読み上げなどの既存フックとも併用できます。
`codex exec` による非対話実行では、プロセスツリーから実行モードを判定して通知を抑制します。

> **SSH 接続時のデスクトップ通知は未対応**: リモート側に GUI が無いため、`agent-notify` は SSH 検出時（`is-ssh`）にデスクトップ通知を行いません。
> ただし tmux のベルマーク付与はリモートの tmux 内で完結するため、SSH でも該当ウィンドウの window-status に目印が付きます。
> リモートからローカル macOS へデスクトップ通知を届ける経路は今後の検討事項です。

## 稼働中エージェントの一覧（agent-session）

`agent-session` は、いま動いている AI エージェント（Claude / Codex / Gemini）の popup セッションを一覧し、そこから復帰（jump）・終了（kill）できる fzf picker です。通知を見逃した・無効にした場合でも、一覧から復帰先を辿れます。通知の有効/無効に依存せず、tmux だけで単体動作します。

`prefix + a`（list Agents）で picker をポップアップ表示します。

| キー | 動作 |
| --- | --- |
| `enter` | 選択したセッションへ復帰（起動元ウィンドウへ移動してから popup を開き直す） |
| `ctrl-x` ×2 | 選択したセッションを終了（1 回目で警告ヘッダを表示し、同じ行でもう一度押すと実行。別の行へ移ると取り消し） |
| `ctrl-r` | 一覧を再読込（STATE を最新化）。picker は自動更新しないため、状態の鮮度を上げたいときに使う |
| `↑` / `↓`・入力 | fzf の絞り込み |

右ペインには `capture-pane` による各セッションのライブプレビューを表示します。テキストで一覧だけ取りたい場合は `agent-session list` を実行します。`STATE` 列を一番左に置き、要対応のものが上に並ぶよう並び替えます。なお picker は開いた時点のスナップショットで、開いている間は自動再描画しません（`ctrl-r` で再読込）。

- **検知の仕組み**: セッション維持型ポップアップ（`prefix + A` / `o` / `G`）で起動した popup セッションには、`dot_tmux_open_persistent_popup_session` が種別マーカー `@agent`（`claude` / `codex` / `gemini`）を刻みます。picker はこの `@agent` 付きセッションを列挙します。エージェントを終了するとセッションも消えるため、tmux のセッション一覧がそのまま「稼働中エージェント」の一覧になります（プロセス走査や常駐は不要）。
- **状態（STATE）表示**: 各セッションの状態を色付きで表示し、要対応のものを上にソートします。一覧に出すのは `working`（🔴 作業中）/ `waiting`（🟡 入力・承認待ち）/ `idle`（🟢 完了・あなたの番）の3値のみ（`wait_reason` はセッションに記録するが列ズレ防止のため一覧には出さない。通知側 `agent-notify` が subtitle で利用する）。状態は Claude/Codex のフックから `agent-session state <mode>` が刻みます（後述）。フック未設定のセッションは `?`（不明）になります。
- **前提**: `fzf`（Brewfile に記載）。`prefix + a` から起動する都合上、`agent-session` に実行権限が必要です（`chmod +x ~/.local/bin/agent-session`）。
- **既知の制約**: `@agent` マーカー追加より前から起動していたセッションは、起動し直すまで一覧に出ません。

### 状態（STATE）表示の設定

状態は通知（`agent-notify`）とは独立に、`agent-session state <mode>` をフックに配線して刻みます。`agent-notify` と同じ `event.sh` で payload を `working` / `waiting` / `idle`（+ `wait_reason`）へ正規化し、`agent-notify` は通知を、`agent-session` はセッションへの状態スタンプを、それぞれ独自に行います。通知と状態表示は併存し、どちらか片方だけでも動きます。

mode と状態の対応:

| agent | フック | mode | state |
| --- | --- | --- | --- |
| Claude | `UserPromptSubmit` | `claude-prompt` | `working` |
| Claude | `PostToolUse`（全ツール） | `claude-posttool` | `working` |
| Claude | `Notification` | `claude-notification` | `waiting`（message から permission / input を判定） |
| Claude | `PreToolUse`（`AskUserQuestion`） | `claude-ask` | `waiting:question` |
| Claude | `Stop` | `claude-stop` | `idle` |
| Codex | `UserPromptSubmit` | `codex-prompt` | `working` |
| Codex | `PostToolUse`（全ツール） | `codex-posttool` | `working` |
| Codex | `PermissionRequest` | `codex-notification` | `waiting:permission` |
| Codex | `Stop` | `codex-stop` | `idle` |

`PostToolUse` を `working` に割り当てているのは、許可承認や質問回答のあと作業を再開した合図を拾い、`waiting` から `working` へ復帰させるためです（これが無いと次の `Stop` まで `waiting` 表示が居座る）。ツール実行ごとに走るため負荷を抑える工夫を入れている: ① `dot_tmux_mark_agent_state` は tmux 呼び出しを 1 回にチェーン、② pane ごとのマーカーファイルで直近状態を覚え、同一状態なら `date`/`tmux` 呼び出しを丸ごと省く。結果、`working` 連続中のスキップ経路は約 15ms/回、状態変化を伴う書き込みでも約 22ms/回。

Claude Code（`~/.claude/settings.json`、既存の `agent-notify` フックへ追記）:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state claude-prompt" }
      ] }
    ],
    "PostToolUse": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state claude-posttool" }
      ] }
    ],
    "PreToolUse": [
      { "matcher": "AskUserQuestion", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state claude-ask" }
      ] }
    ],
    "Notification": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state claude-notification" }
      ] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state claude-stop" }
      ] }
    ]
  }
}
```

Codex（`~/.codex/hooks.json`）:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state codex-prompt" }
      ] }
    ],
    "PostToolUse": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state codex-posttool" }
      ] }
    ],
    "PermissionRequest": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state codex-notification" }
      ] }
    ],
    "Stop": [
      { "hooks": [
        { "type": "command", "command": "/Users/<user>/.local/bin/agent-session state codex-stop" }
      ] }
    ]
  }
}
```

> `agent-session state` は通知を出さず、状態スタンプ（`@agent_state` 等）のみを行います。stdout には何も書かないため、`PermissionRequest` の decision は併設の `agent-notify codex-notification` 側が返します。Codex には AskUserQuestion 相当が無いため `claude-ask` の対応はありません。

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
