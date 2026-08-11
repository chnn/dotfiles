# Resume a Pi session from any project using Television.
# Usage: pir [pi-options...]
pir() {
  emulate -L zsh

  local dependency
  for dependency in tv node pi; do
    if ! (( $+commands[$dependency] )); then
      print -u2 "pir: $dependency is not installed"
      return 1
    fi
  done

  local helper="${XDG_CONFIG_HOME:-$HOME/.config}/television/scripts/pi-sessions.mjs"
  local selection cwd session_file
  # Keep recency ordering and prevent selecting multiple sessions with Tab.
  selection=$(tv pi-sessions --no-sort --no-preview --no-remote \
    --keybindings 'tab="select_next_entry";backtab="select_prev_entry"') || return $?
  [[ -n "$selection" ]] || return 0

  {
    IFS= read -r -d '' cwd && IFS= read -r -d '' session_file
  } < <(node "$helper" resolve "$selection") || return 1

  if [[ ! -d "$cwd" ]]; then
    print -u2 "pir: session directory no longer exists: $cwd"
    return 1
  fi
  [[ -f "$session_file" ]] || { print -u2 "pir: session file no longer exists: $session_file"; return 1; }

  builtin cd -- "$cwd" || return 1
  command pi --session "$session_file" "$@"
}
