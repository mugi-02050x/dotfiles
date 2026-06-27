#!/bin/sh
# Normalize raw Claude/Codex payloads into a shared agent event shape.
# The normalized event is intentionally independent from notification backends so
# future consumers can reuse the same parsed agent/state/wait_reason/cwd/message data.
#
# The canonical lifecycle state is one of: working / waiting / idle.
# wait_reason qualifies the waiting state only (permission / question / input);
# it is empty for working and idle. Consumers interpret these on their own:
# agent-notify renders notifications, agent-session stamps the tmux session.

# These globals form this library's public surface; they are read by sourcing
# scripts (agent-notify / agent-session), so shellcheck cannot see their use here.
# shellcheck disable=SC2034
AGENT_EVENT_AGENT=
AGENT_EVENT_STATE=
AGENT_EVENT_WAIT_REASON=
AGENT_EVENT_CWD=
AGENT_EVENT_MESSAGE=

# Codex PermissionRequest hooks may return a JSON decision object; return the
# default empty decision for the notification-only hook. Stop hooks are
# notification-only here, so keep stdout empty to avoid invalid output handling.
agent_event_requires_stdout_response() {
  case "${1:-}" in
    codex-notification) return 0 ;;
  esac
  return 1
}

# Detect whether this Codex event was launched from non-interactive `codex exec`.
# Codex payloads do not include the CLI execution mode, so inspect parent commands.
agent_event_is_codex_exec() {
  agent_event_ancestors="$(dot_process_list_ancestors "$$" 30)"
  printf '%s\n' "$agent_event_ancestors" | while IFS='|' read -r agent_event_pid agent_event_command; do
    [ -n "$agent_event_pid" ] || continue
    # Avoid matching prompt text or parent shell arguments that merely mention `codex exec`.
    # Intentional word splitting: break the command line into argv positions.
    # shellcheck disable=SC2086
    set -- $agent_event_command
    agent_event_executable="${1:-}"
    agent_event_executable="${agent_event_executable##*/}"
    agent_event_arg2="${2:-}"
    agent_event_arg2="${agent_event_arg2##*/}"
    if [ "$agent_event_executable" = codex ] && [ "${2:-}" = exec ]; then
      return 0
    fi
    case "$agent_event_executable:$agent_event_arg2:${3:-}" in
      sh:codex:exec|bash:codex:exec|zsh:codex:exec|node:codex.js:exec) return 0 ;;
    esac
    false
  done
}

# Read the payload for a Claude/Codex event mode and set AGENT_EVENT_* globals.
# These fields describe the agent event itself; notifier-specific formatting
# belongs in agent/notifier.sh and session-stamp formatting in agent-session.
agent_event_normalize() {
  agent_event_mode="${1:-}"
  agent_event_arg_payload="${2:-}"

  AGENT_EVENT_AGENT=
  AGENT_EVENT_STATE=
  AGENT_EVENT_WAIT_REASON=
  AGENT_EVENT_CWD=
  AGENT_EVENT_MESSAGE=

  case "$agent_event_mode" in
    claude-prompt|claude-posttool)
      # working へ遷移する Claude のイベント。
      #   claude-prompt   = UserPromptSubmit（ユーザーが作業を渡した直後）
      #   claude-posttool = PostToolUse（ツール実行直後 = 許可承認や質問回答のあと
      #                     作業を再開した合図。waiting からの復帰に使う）
      AGENT_EVENT_AGENT=claude
      AGENT_EVENT_STATE=working
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      ;;
    claude-ask)
      # PreToolUse for the AskUserQuestion tool: Claude is waiting on an answer.
      AGENT_EVENT_AGENT=claude
      AGENT_EVENT_STATE=waiting
      AGENT_EVENT_WAIT_REASON=question
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '
        .tool_input.questions[0].question // empty
      ' 2>/dev/null || true)"
      ;;
    claude-stop)
      AGENT_EVENT_AGENT=claude
      AGENT_EVENT_STATE=idle
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      agent_event_transcript="$(printf '%s' "$agent_event_payload" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
      # Use the latest assistant text as the preview when the transcript is available.
      if [ -n "$agent_event_transcript" ] && [ -f "$agent_event_transcript" ]; then
        AGENT_EVENT_MESSAGE="$(tail -n 50 "$agent_event_transcript" 2>/dev/null | jq -rs '
          [ .[]
            | select(.type == "assistant")
            | .message.content[]?
            | select(.type == "text")
            | .text
          ] | last // empty
        ' 2>/dev/null || true)"
      fi
      ;;
    claude-notification)
      AGENT_EVENT_AGENT=claude
      AGENT_EVENT_STATE=waiting
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.message // empty' 2>/dev/null || true)"
      # The Notification hook covers both permission prompts and plain idle input
      # waits; classify by message text (matcher-based detection is wired separately).
      case "$AGENT_EVENT_MESSAGE" in
        *permission*|*approve*|*承認*) AGENT_EVENT_WAIT_REASON=permission ;;
        *) AGENT_EVENT_WAIT_REASON=input ;;
      esac
      ;;
    codex-prompt|codex-posttool)
      # working へ遷移する Codex のイベント（UserPromptSubmit / PostToolUse）。
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE=working
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      ;;
    codex-stop)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE=idle
      agent_event_payload="$(cat)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      ;;
    codex-notification)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE=waiting
      AGENT_EVENT_WAIT_REASON=permission
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '
        .reason // .message //
        (if .tool_name then "承認が必要です: " + .tool_name else empty end)
      ' 2>/dev/null || true)"
      ;;
    codex)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE=idle
      agent_event_payload="$agent_event_arg_payload"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.["last-assistant-message"] // empty' 2>/dev/null || true)"
      AGENT_EVENT_CWD="$PWD"
      ;;
    *)
      return 2
      ;;
  esac

  [ -n "$AGENT_EVENT_CWD" ] || AGENT_EVENT_CWD="$PWD"
}
