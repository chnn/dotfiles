wtn() {
  emulate -L zsh
  setopt local_options pipe_fail

  local slug="$1"
  if [[ -z "$slug" ]]; then
    print -u2 "wtn: usage: wtn <slug>"
    return 1
  fi
  if [[ "$slug" == */* ]]; then
    print -u2 "wtn: slug must not contain '/' (got '$slug')"
    return 1
  fi

  # Find the main worktree (first entry from `git worktree list`).
  local root
  root=$(git worktree list --porcelain 2>/dev/null \
    | awk '/^worktree / { print $2; exit }')
  if [[ -z "$root" ]]; then
    print -u2 "wtn: not in a git repository"
    return 1
  fi

  local repo_name=${root:t}
  local wt_path=${root:h}/${repo_name}-${slug}

  if [[ -e "$wt_path" ]]; then
    print -u2 "wtn: directory already exists: $wt_path"
    return 1
  fi

  # Detect main branch via origin/HEAD, falling back to main/master/trunk.
  local main_branch
  if main_branch=$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
    main_branch=${main_branch#refs/remotes/origin/}
  else
    local b
    for b in main master trunk; do
      if git -C "$root" rev-parse --verify "origin/$b" >/dev/null 2>&1; then
        main_branch=$b
        break
      fi
    done
  fi
  if [[ -z "$main_branch" ]]; then
    print -u2 "wtn: could not detect main branch (no origin/HEAD and no main/master/trunk on origin)"
    return 1
  fi

  local branch="chnn/${slug}"

  # Redirect git's stdout to stderr so only the worktree path lands on
  # our stdout (wtnp captures it via command substitution).
  print -u2 "wtn: git fetch origin ${main_branch}"
  git -C "$root" fetch origin "$main_branch" >&2 || return 1

  print -u2 "wtn: git worktree add --no-track -b ${branch} ${wt_path} origin/${main_branch}"
  git -C "$root" worktree add --no-track -b "$branch" "$wt_path" "origin/${main_branch}" >&2 || return 1

  local hook="$root/.post-worktree.sh"
  if [[ -f "$hook" ]]; then
    print -u2 "wtn: running $hook"
    ( cd "$wt_path" && WT_ROOT="$root" WT_NEW="$wt_path" bash "$hook" ) || {
      print -u2 "wtn: $hook failed"
      return 1
    }
  fi

  print -u2 "wtn: created worktree '${slug}' on branch ${branch}"
  print -r -- "$wt_path"
}

# Like wtn, but first opens $EDITOR on /tmp/prompt-<slug> to capture a
# prompt, then after creating the worktree cd's into it and runs `pi`
# with the prompt.
wtnp() {
  emulate -L zsh
  setopt local_options pipe_fail

  local slug="$1"
  if [[ -z "$slug" ]]; then
    print -u2 "wtnp: usage: wtnp <slug>"
    return 1
  fi

  local prompt_file="/tmp/prompt-${slug}"
  "${EDITOR:-vi}" "$prompt_file" </dev/tty >/dev/tty || {
    print -u2 "wtnp: editor exited non-zero, aborting"
    return 1
  }
  if [[ ! -s "$prompt_file" ]]; then
    print -u2 "wtnp: $prompt_file is empty, aborting"
    return 1
  fi

  local wt_path
  wt_path=$(wtn "$slug") || return 1

  cd "$wt_path" || return 1
  pi "$(<$prompt_file)"
}
