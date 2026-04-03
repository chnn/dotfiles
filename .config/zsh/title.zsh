# Automatic terminal title: "{repo} | {label}" or "{dir}"
#
# Add new rules to _title_program_labels below.
# Keys are program names as they appear in the command line.
# Values are the label shown in the title.

typeset -A _title_program_labels=(
  [nvim]="editor"
  [vim]="editor"
  [vi]="editor"
  [e]="editor"
  [claude]="agent"
  [ranger]="files"
  [f]="files"
  [ssh]="ssh"
  [python]="python"
  [python3]="python"
  [node]="node"
  [ruby]="ruby"
  [cargo]="cargo"
  [make]="build"
  [docker]="docker"
  [htop]="monitor"
  [top]="monitor"
  [less]="pager"
  [man]="manual"
)

_title_repo_name() {
  if [[ "$PWD" != "$_title_cached_pwd" ]]; then
    _title_cached_pwd="$PWD"
    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    _title_cached_repo="${toplevel:t}"
  fi
  echo "$_title_cached_repo"
}

_title_set() {
  print -Pn "\e]2;$1\a"
}

_title_parse_cmd() {
  local cmd="$1"

  # Strip leading env var assignments (e.g., FOO=bar nvim)
  while [[ "$cmd" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; do
    cmd="${cmd#* }"
  done

  # Strip common command prefixes
  local prog="${cmd%% *}"
  while [[ "$prog" == (sudo|command|exec|noglob|nocorrect|time|nice|ionice) ]]; do
    cmd="${cmd#* }"
    prog="${cmd%% *}"
  done

  echo "${prog:t}"
}

_title_precmd() {
  local repo
  repo=$(_title_repo_name)

  if [[ -n "$repo" ]]; then
    _title_set "$repo"
  else
    _title_set "${PWD:t}"
  fi
}

_title_preexec() {
  local prog
  prog=$(_title_parse_cmd "$1")

  local label="${_title_program_labels[$prog]}"
  [[ -z "$label" ]] && return

  local repo
  repo=$(_title_repo_name)
  local prefix="${repo:-${PWD:t}}"

  _title_set "$prefix | $label"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _title_precmd
add-zsh-hook preexec _title_preexec
