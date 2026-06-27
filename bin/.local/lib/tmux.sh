#!/bin/sh
# Shared tmux helpers used by local scripts.

DOT_TMUX_LIB_DIR="${DOT_TMUX_LIB_DIR:-$HOME/.local/lib}"
if ! command -v dot_process_list_ancestors >/dev/null 2>&1 && [ -f "$DOT_TMUX_LIB_DIR/process.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOT_TMUX_LIB_DIR/process.sh"
fi

DOT_TMUX_BIN="${DOT_TMUX_BIN:-}"
DOT_TMUX_POPUP_WIDTH_PERCENT="${DOT_TMUX_POPUP_WIDTH_PERCENT:-90}"
DOT_TMUX_POPUP_HEIGHT_PERCENT="${DOT_TMUX_POPUP_HEIGHT_PERCENT:-90}"

# 利用可能な tmux 実行ファイルのパスを返す。
dot_tmux_find_executable() {
  if [ -n "${DOT_TMUX_BIN:-}" ] && [ -x "$DOT_TMUX_BIN" ]; then
    printf '%s' "$DOT_TMUX_BIN"
    return 0
  fi

  if [ -x /opt/homebrew/bin/tmux ]; then
    DOT_TMUX_BIN=/opt/homebrew/bin/tmux
  else
    DOT_TMUX_BIN="$(command -v tmux 2>/dev/null || true)"
  fi

  [ -n "$DOT_TMUX_BIN" ] || return 1
  printf '%s' "$DOT_TMUX_BIN"
}

# popup session 名や起動元 window 照合に使う、パス由来の短い安定キーを返す。
dot_tmux_popup_path_hash() {
  dot_tmux_path="${1:-}"
  if command -v md5sum >/dev/null 2>&1; then
    printf '%s\n' "$dot_tmux_path" | md5sum | cut -c1-8
  elif command -v md5 >/dev/null 2>&1; then
    printf '%s\n' "$dot_tmux_path" | md5 -q | cut -c1-8
  elif [ -x /sbin/md5 ]; then
    printf '%s\n' "$dot_tmux_path" | /sbin/md5 -q | cut -c1-8
  else
    return 1
  fi
}

# Neovim の :terminal 等で TMUX_PANE が継承されない場合に、自プロセスの親を辿って
# tmux の pane_pid と一致するペインを特定する。tmux 外なら見つからず失敗する。
dot_tmux_resolve_pane_via_pid() {
  command -v dot_process_list_ancestors >/dev/null 2>&1 || return 1
  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  dot_tmux_panes="$("$dot_tmux_tmux" list-panes -a -F '#{pane_pid} #{pane_id}' 2>/dev/null)" || return 1
  [ -n "$dot_tmux_panes" ] || return 1

  dot_tmux_ancestors="$(dot_process_list_ancestors "$$" 30)"
  printf '%s\n' "$dot_tmux_ancestors" | while IFS='|' read -r dot_tmux_pid _dot_tmux_command; do
    [ -n "$dot_tmux_pid" ] || continue
    dot_tmux_match="$(printf '%s\n' "$dot_tmux_panes" | awk -v p="$dot_tmux_pid" '$1==p{print $2; exit}')"
    if [ -n "$dot_tmux_match" ]; then
      printf '%s' "$dot_tmux_match"
      return 0
    fi
    false
  done
}

# ポップアップ起動セッション（@popup マーカー付き）かどうかを判定する。
# このリポジトリの tmux ポップアップ（prefix+a 等）は生成時に @popup=1 を設定する。
dot_tmux_is_popup_session() {
  dot_tmux_session="${1:-}"
  [ -n "$dot_tmux_session" ] || return 1
  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  [ "$("$dot_tmux_tmux" show-options -t "$dot_tmux_session" -qv @popup 2>/dev/null)" = 1 ]
}

# ポップアップ以外（ユーザーのメイン）クライアント名を 1 つ返す。
dot_tmux_find_main_client() {
  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  for dot_tmux_client in $("$dot_tmux_tmux" list-clients -F '#{client_name}::#{client_session}' 2>/dev/null); do
    if ! dot_tmux_is_popup_session "${dot_tmux_client##*::}"; then
      printf '%s' "${dot_tmux_client%%::*}"
      return 0
    fi
  done
  return 1
}

# 指定 session にアタッチ中の client が存在するか判定する。
dot_tmux_session_has_client() {
  dot_tmux_session="${1:-}"
  [ -n "$dot_tmux_session" ] || return 1
  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  [ -n "$("$dot_tmux_tmux" list-clients -t "$dot_tmux_session" -F '#{client_name}' 2>/dev/null)" ]
}

# 指定パスと一致する非ポップアップ window（＝ポップアップの起動元）を
# "session_name|window_id|pane_tty" で返す。
dot_tmux_find_origin_window_by_path() {
  dot_tmux_origin_path="${1:-}"
  [ -n "$dot_tmux_origin_path" ] || return 1

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  dot_tmux_target_key="$(dot_tmux_popup_path_hash "$dot_tmux_origin_path")"
  "$dot_tmux_tmux" list-panes -a -F '#{pane_active}|#{session_name}|#{window_id}|#{pane_tty}|#{pane_current_path}' 2>/dev/null \
  | while IFS='|' read -r dot_tmux_active dot_tmux_session dot_tmux_window dot_tmux_tty dot_tmux_path; do
      [ "$dot_tmux_active" = 1 ] || continue
      dot_tmux_is_popup_session "$dot_tmux_session" && continue
      dot_tmux_candidate_key="$(dot_tmux_popup_path_hash "$dot_tmux_path")"
      [ "$dot_tmux_candidate_key" = "$dot_tmux_target_key" ] || continue
      # 名前が自パスのハッシュで終わるセッションはポップアップ型（@popup 未設定の旧
      # セッションも含む）。起動元として誤検出しないよう構造的に除外する。
      case "$dot_tmux_session" in *-"$dot_tmux_candidate_key") continue ;; esac
      printf '%s|%s|%s' "$dot_tmux_session" "$dot_tmux_window" "$dot_tmux_tty"
      break
    done
}

# 指定 pane に対応する本来の window を解決し、"session_name|window_id|pane_tty" で返す。
# 通常 pane ならその pane、popup session なら起動元 window の active pane を返す。
# 通知・status line・フォーカス復帰・agent 一覧からの復帰など、用途を問わず共通で使う。
dot_tmux_resolve_origin_window() {
  dot_tmux_pane="${1:-}"
  dot_tmux_cwd="${2:-}"
  [ -n "$dot_tmux_pane" ] || return 1

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  dot_tmux_session="$("$dot_tmux_tmux" display-message -p -t "$dot_tmux_pane" '#{session_name}' 2>/dev/null || true)"
  [ -n "$dot_tmux_session" ] || return 1

  if dot_tmux_is_popup_session "$dot_tmux_session"; then
    # 起動元パスは popup ペインの tmux カレントパスから取得し、候補側（list-panes の
    # pane_current_path）と同じ正規化（例: /tmp→/private/tmp）でハッシュ照合する。
    dot_tmux_related_path="$("$dot_tmux_tmux" display-message -p -t "$dot_tmux_pane" '#{pane_current_path}' 2>/dev/null || true)"
    [ -n "$dot_tmux_related_path" ] || dot_tmux_related_path="$dot_tmux_cwd"
    dot_tmux_find_origin_window_by_path "$dot_tmux_related_path"
  else
    "$dot_tmux_tmux" display-message -p -t "$dot_tmux_pane" '#{session_name}|#{window_id}|#{pane_tty}' 2>/dev/null
  fi
}

# 指定 pane の通知対象 window へ BEL を送り、tmux の window bell flag を立てる。
# 通常 pane ならその pane、popup session なら起動元 window の active pane を対象にする。
dot_tmux_send_bell_to_notification_target_window() {
  dot_tmux_related="$(dot_tmux_resolve_origin_window "${1:-}" "${2:-}" || true)"
  dot_tmux_tty="${dot_tmux_related##*|}"

  [ -n "$dot_tmux_tty" ] && printf '\a' > "$dot_tmux_tty" 2>/dev/null || true
  return 0
}

# 指定 pane の通知対象 window を status line 表示用の "#I:#W" ラベルで返す。
dot_tmux_statusline_notification_target_label() {
  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 0
  dot_tmux_related="$(dot_tmux_resolve_origin_window "${1:-}" "${2:-}" || true)"
  [ -n "$dot_tmux_related" ] || return 0
  dot_tmux_related_rest="${dot_tmux_related#*|}"
  dot_tmux_target_window="${dot_tmux_related_rest%%|*}"
  "$dot_tmux_tmux" display-message -p -t "$dot_tmux_target_window" '#{window_index}:#{window_name}' 2>/dev/null || true
}

# 指定コマンドをセッションを保持しない popup window として開く。
# セッション維持型 popup と同じサイズ設定を使い、表示サイズを揃える。
dot_tmux_open_transient_popup_window() {
  dot_tmux_popup_cmd="${1:-}"
  dot_tmux_current_path="${2:-}"

  [ -n "$dot_tmux_popup_cmd" ] || return 1
  [ -n "$dot_tmux_current_path" ] || return 1

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  "$dot_tmux_tmux" display-popup \
    -d "$dot_tmux_current_path" \
    -w "${DOT_TMUX_POPUP_WIDTH_PERCENT}%" \
    -h "${DOT_TMUX_POPUP_HEIGHT_PERCENT}%" \
    -E "$dot_tmux_popup_cmd"
}

# 指定コマンドをセッション維持型 popup として開く。
# 同じ名前・パスの popup session が既にある場合は、サイズだけ更新して再アタッチする。
dot_tmux_open_persistent_popup_session() {
  dot_tmux_popup_name="${1:-}"
  dot_tmux_popup_cmd="${2:-}"
  dot_tmux_current_path="${3:-}"
  dot_tmux_client_width="${4:-0}"
  dot_tmux_client_height="${5:-0}"

  [ -n "$dot_tmux_popup_name" ] || return 1
  [ -n "$dot_tmux_popup_cmd" ] || return 1
  [ -n "$dot_tmux_current_path" ] || return 1

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 1
  dot_tmux_session="${dot_tmux_popup_name}-$(dot_tmux_popup_path_hash "$dot_tmux_current_path")"
  dot_tmux_popup_width=$((dot_tmux_client_width * DOT_TMUX_POPUP_WIDTH_PERCENT / 100))
  dot_tmux_popup_height=$((dot_tmux_client_height * DOT_TMUX_POPUP_HEIGHT_PERCENT / 100))

  if "$dot_tmux_tmux" has-session -t "$dot_tmux_session" 2>/dev/null; then
    "$dot_tmux_tmux" resize-window -t "$dot_tmux_session" -x "$dot_tmux_popup_width" -y "$dot_tmux_popup_height"
  else
    "$dot_tmux_tmux" new-session -d -s "$dot_tmux_session" \
      -c "$dot_tmux_current_path" \
      -x "$dot_tmux_popup_width" -y "$dot_tmux_popup_height" \
      "$dot_tmux_popup_cmd"
    "$dot_tmux_tmux" set-option -t "$dot_tmux_session" window-size latest
    "$dot_tmux_tmux" set-option -t "$dot_tmux_session" @popup 1
    # 稼働中 agent の一覧（agent-session）が種別付きで検知できるようマーカーを刻む。
    "$dot_tmux_tmux" set-option -t "$dot_tmux_session" @agent "$dot_tmux_popup_name"
  fi

  "$dot_tmux_tmux" display-popup \
    -w "${DOT_TMUX_POPUP_WIDTH_PERCENT}%" \
    -h "${DOT_TMUX_POPUP_HEIGHT_PERCENT}%" \
    -E "$dot_tmux_tmux attach-session -t \"$dot_tmux_session\""
}

# 指定 pane へフォーカスを戻す。popup session の場合は起動元 window を選んでから popup を開き直す。
dot_tmux_focus_pane() {
  dot_tmux_pane="${1:-}"
  [ -n "$dot_tmux_pane" ] || return 0

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 0
  dot_tmux_info="$("$dot_tmux_tmux" display-message -p -t "$dot_tmux_pane" '#{session_name}|#{window_id}|#{pane_id}' 2>/dev/null || true)"
  dot_tmux_session="${dot_tmux_info%%|*}"
  dot_tmux_rest="${dot_tmux_info#*|}"
  dot_tmux_window="${dot_tmux_rest%%|*}"
  dot_tmux_pane_id="${dot_tmux_rest##*|}"

  if [ -z "$dot_tmux_session" ]; then
    return 0
  elif dot_tmux_is_popup_session "$dot_tmux_session"; then
    # ポップアップセッションは display-popup 経由で表示する設計。
    # ポップアップのアタッチ先（ポップアップセッション）へ switch-client すると、
    # デタッチ時に元セッションへ戻れず tmux を抜けてしまうため行わない。
    dot_tmux_main_client="$(dot_tmux_find_main_client || true)"
    if [ -n "$dot_tmux_main_client" ]; then
      dot_tmux_origin="$(dot_tmux_resolve_origin_window "$dot_tmux_pane" || true)"
      if [ -n "$dot_tmux_origin" ]; then
        dot_tmux_origin_session="${dot_tmux_origin%%|*}"
        dot_tmux_origin_rest="${dot_tmux_origin#*|}"
        dot_tmux_origin_window="${dot_tmux_origin_rest%%|*}"
        "$dot_tmux_tmux" switch-client -c "$dot_tmux_main_client" -t "$dot_tmux_origin_session" 2>/dev/null || true
        "$dot_tmux_tmux" select-window -t "$dot_tmux_origin_window" 2>/dev/null || true
      fi
      if ! dot_tmux_session_has_client "$dot_tmux_session"; then
        "$dot_tmux_tmux" display-popup -c "$dot_tmux_main_client" \
          -w "${DOT_TMUX_POPUP_WIDTH_PERCENT}%" -h "${DOT_TMUX_POPUP_HEIGHT_PERCENT}%" \
          -E "$dot_tmux_tmux attach-session -t \"$dot_tmux_session\"" 2>/dev/null || true
      fi
    fi
  else
    "$dot_tmux_tmux" select-window -t "$dot_tmux_window" 2>/dev/null || true
    "$dot_tmux_tmux" select-pane -t "$dot_tmux_pane_id" 2>/dev/null || true
    if ! dot_tmux_session_has_client "$dot_tmux_session"; then
      dot_tmux_main_client="$(dot_tmux_find_main_client || true)"
      if [ -n "$dot_tmux_main_client" ]; then
        "$dot_tmux_tmux" switch-client -c "$dot_tmux_main_client" -t "$dot_tmux_session" 2>/dev/null || true
      fi
    fi
  fi
}

# 指定 pane の所属セッションへ agent のライフサイクル状態を刻む。
#   引数: <pane> <state: working|waiting|idle> [wait_reason: permission|question|input]
# agent-session の一覧/picker が #{@agent_state} 等を読んで表示する。pane 未指定や
# tmux 外・セッション解決不可なら no-op（フックから安全に呼べる）。@agent_state_at は
# 経過時間表示用の epoch。wait_reason は state==waiting のときだけ意味を持つ（読む側で
# ゲートするため、working/idle 遷移時のクリアは不要だが、stale を避けるため毎回上書きする）。
dot_tmux_mark_agent_state() {
  dot_tmux_pane="${1:-}"
  dot_tmux_state="${2:-}"
  dot_tmux_wait_reason="${3:-}"
  [ -n "$dot_tmux_pane" ] && [ -n "$dot_tmux_state" ] || return 0

  dot_tmux_tmux="$(dot_tmux_find_executable)" || return 0
  dot_tmux_session="$("$dot_tmux_tmux" display-message -p -t "$dot_tmux_pane" '#{session_name}' 2>/dev/null || true)"
  [ -n "$dot_tmux_session" ] || return 0

  "$dot_tmux_tmux" set-option -t "$dot_tmux_session" @agent_state "$dot_tmux_state" 2>/dev/null || return 0
  "$dot_tmux_tmux" set-option -t "$dot_tmux_session" @agent_state_at "$(date +%s 2>/dev/null || echo 0)" 2>/dev/null || true
  "$dot_tmux_tmux" set-option -t "$dot_tmux_session" @agent_wait_reason "$dot_tmux_wait_reason" 2>/dev/null || true
}
