#!/bin/sh
# Normalize raw Claude/Codex payloads into a shared agent event shape.
# The normalized event is intentionally independent from notification backends so
# future consumers can reuse the same parsed agent/cwd/state/message data.

AGENT_EVENT_AGENT=
AGENT_EVENT_STATE=
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
# belongs in agent/notifier.sh.
agent_event_normalize() {
  agent_event_mode="${1:-}"
  agent_event_arg_payload="${2:-}"

  AGENT_EVENT_AGENT=
  AGENT_EVENT_STATE=
  AGENT_EVENT_CWD=
  AGENT_EVENT_MESSAGE=

  case "$agent_event_mode" in
    claude-stop)
      AGENT_EVENT_AGENT=claude
      AGENT_EVENT_STATE="ターン完了"
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
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.message // empty' 2>/dev/null || true)"
      case "$AGENT_EVENT_MESSAGE" in
        *permission*|*approve*|*承認*) AGENT_EVENT_STATE="承認待ち" ;;
        *) AGENT_EVENT_STATE="入力待ち" ;;
      esac
      ;;
    codex-stop)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE="ターン完了"
      agent_event_payload="$(cat)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      ;;
    codex-notification)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE="承認待ち"
      agent_event_payload="$(cat)"
      AGENT_EVENT_CWD="$(printf '%s' "$agent_event_payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '
        .reason // .message //
        (if .tool_name then "承認が必要です: " + .tool_name else empty end)
      ' 2>/dev/null || true)"
      ;;
    codex)
      AGENT_EVENT_AGENT=codex
      AGENT_EVENT_STATE="ターン完了"
      agent_event_payload="$agent_event_arg_payload"
      AGENT_EVENT_MESSAGE="$(printf '%s' "$agent_event_payload" | jq -r '.["last-assistant-message"] // empty' 2>/dev/null || true)"
      AGENT_EVENT_CWD="$PWD"
      ;;
    *)
      return 2
      ;;
  esac

  [ -n "$AGENT_EVENT_CWD" ] || AGENT_EVENT_CWD="$PWD"
  [ -n "$AGENT_EVENT_MESSAGE" ] || AGENT_EVENT_MESSAGE="$AGENT_EVENT_STATE"
}
