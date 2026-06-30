#!/bin/sh
# Notification backends and presentation helpers for agent events.

AGENT_NOTIFY_TTL="${AGENT_NOTIFY_TTL:-60}"
AGENT_NOTIFY_WIDTH="${AGENT_NOTIFY_WIDTH:-70}"

# Collapse newlines and cap the desktop notification body length.
agent_notifier_message_preview() {
  printf '%s' "${1:-}" | tr '\n' ' ' | cut -c1-140
}

# Clip a string by terminal display width. East Asian wide/fullwidth chars count as 2.
agent_notifier_clip_width() {
  if command -v perl >/dev/null 2>&1; then
    MAXW="$1" perl -CSAD -e '
      my $max = $ENV{MAXW} || 70;
      my $ell = "..."; my $elen = 3;
      local $/; my $s = <STDIN>; $s //= "";
      my @ch = split //, $s;
      my $cw = sub { $_[0] =~ /\p{East_Asian_Width=Wide}|\p{East_Asian_Width=Fullwidth}/ ? 2 : 1 };
      my $total = 0; $total += $cw->($_) for @ch;
      if ($total <= $max) { print $s; exit; }
      my $budget = $max - $elen; $budget = 0 if $budget < 0;
      my ($w, $o) = (0, "");
      for my $c (@ch) {
        my $x = $cw->($c);
        last if $w + $x > $budget;
        $o .= $c; $w += $x;
      }
      print $o . $ell;
    '
  else
    agent_notifier_clip_s="$(cat)"
    if [ "$(printf '%s' "$agent_notifier_clip_s" | cut -c1-"$1")" = "$agent_notifier_clip_s" ]; then
      printf '%s' "$agent_notifier_clip_s"
    else
      printf '%s...' "$(printf '%s' "$agent_notifier_clip_s" | cut -c1-"$(( $1 - 3 ))")"
    fi
  fi
}

# Show a temporary status-right notification. This works over SSH because tmux renders it server-side.
agent_notifier_show_status_line() {
  agent_notifier_pane="${1:-}"
  agent_notifier_cwd="${2:-}"
  agent_notifier_agent="${3:-}"
  agent_notifier_state="${4:-}"

  agent_notifier_tmux="$(dot_tmux_find_executable)" || return 0
  agent_notifier_project="$(basename "$agent_notifier_cwd")"
  agent_notifier_win="$(dot_tmux_statusline_notification_target_label "$agent_notifier_pane" "$agent_notifier_cwd" 2>/dev/null || true)"
  # window ラベル(#I:#W)はリポジトリ名=パス basename と重複するため、ラベルがあれば
  # それを location に使い、取れない場合だけプロジェクト名へフォールバックする。
  agent_notifier_location="${agent_notifier_win:-$agent_notifier_project}"
  # status line にはメッセージ本文を出さず、場所・agent・状態までに留める（issue #76）。
  # メッセージはデスクトップ通知側（agent_notifier_send_desktop）にのみ渡す。
  agent_notifier_text="$agent_notifier_location $agent_notifier_agent ▸ $agent_notifier_state"
  # Collapse control characters before storing the text in a global tmux option.
  agent_notifier_text="$(printf '%s' "$agent_notifier_text" | tr '\n\r\t' '   ' | agent_notifier_clip_width "$AGENT_NOTIFY_WIDTH")"
  agent_notifier_token="$$-$(date +%s 2>/dev/null || echo 0)"

  "$agent_notifier_tmux" set -g @agent_notify_text "$agent_notifier_text" 2>/dev/null || return 0
  "$agent_notifier_tmux" set -g @agent_notify_token "$agent_notifier_token" 2>/dev/null || true
  "$agent_notifier_tmux" refresh-client -S 2>/dev/null || true
  "$agent_notifier_tmux" run-shell -b "sleep $AGENT_NOTIFY_TTL; \
    if [ \"\$($agent_notifier_tmux show-options -gqv @agent_notify_token)\" = \"$agent_notifier_token\" ]; then \
      $agent_notifier_tmux set -g @agent_notify_text ''; \
      $agent_notifier_tmux set -g @agent_notify_token ''; \
      $agent_notifier_tmux refresh-client -S; \
    fi" 2>/dev/null || true
}

# Send a desktop notification when a local GUI notifier is available.
agent_notifier_send_desktop() {
  agent_notifier_bin_dir="${1:-}"
  agent_notifier_pane="${2:-}"
  agent_notifier_cwd="${3:-}"
  agent_notifier_agent="${4:-}"
  agent_notifier_state="${5:-}"
  agent_notifier_message="${6:-}"

  # Remote SSH sessions have no local GUI; tmux attention/status notifications already ran.
  if [ -x "$agent_notifier_bin_dir/is-ssh" ] && "$agent_notifier_bin_dir/is-ssh" 2>/dev/null; then
    return 0
  fi

  agent_notifier_notifier="$(command -v terminal-notifier 2>/dev/null || true)"
  if [ -z "$agent_notifier_notifier" ]; then
    open -a iTerm 2>/dev/null || true
    return 0
  fi

  if [ "$agent_notifier_state" = "承認待ち" ]; then
    agent_notifier_sound=Glass
  else
    agent_notifier_sound=Sosumi
  fi

  agent_notifier_project="$(basename "$agent_notifier_cwd")"
  agent_notifier_title="$agent_notifier_agent ▸ $agent_notifier_project"
  agent_notifier_group="$agent_notifier_agent-${agent_notifier_pane:-nopane}"

  set -- \
    -title "$agent_notifier_title" \
    -subtitle "$agent_notifier_state" \
    -message "$agent_notifier_message" \
    -group "$agent_notifier_group" \
    -sound "$agent_notifier_sound"

  # terminal-notifier ignores -activate when -execute is also present, so the hook opens iTerm.
  if [ -n "$agent_notifier_pane" ]; then
    set -- "$@" -execute "/bin/sh $agent_notifier_bin_dir/tmux-focus-pane-hook $agent_notifier_pane"
  else
    set -- "$@" -activate com.googlecode.iterm2
  fi

  ( "$agent_notifier_notifier" "$@" >/dev/null 2>&1 & ) 2>/dev/null || true
}
