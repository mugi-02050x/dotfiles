#!/bin/sh
# Shared process-tree helpers used by local scripts.

# Print the current process and its ancestors as "pid|command" lines.
dot_process_list_ancestors() {
  dot_process_pid="${1:-$$}"
  dot_process_limit="${2:-30}"
  dot_process_i=0

  while [ "${dot_process_pid:-0}" -gt 1 ] && [ "$dot_process_i" -lt "$dot_process_limit" ]; do
    dot_process_command="$(ps -o command= -p "$dot_process_pid" 2>/dev/null || true)"
    printf '%s|%s\n' "$dot_process_pid" "$dot_process_command"
    dot_process_pid="$(ps -o ppid= -p "$dot_process_pid" 2>/dev/null | tr -d ' ')"
    dot_process_i=$((dot_process_i + 1))
  done
}
