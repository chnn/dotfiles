set -o emacs

export EDITOR="nvim"

alias e="$EDITOR"
alias ls="ls -l"
alias ns='cd "$NOTES" && $EDITOR && cd -'
alias g="git"
alias gca="git add -A && g commit"
alias gs='git status -sb'
alias gsu='git status -sb -uno'
alias gd='git diff'
alias gdt='git difftool -d -t nvim_difftool'
alias glo='git log --oneline -n 10'
alias gb='git branch --sort=-committerdate'
alias gcb='git checkout $(git branch --sort=-committerdate | fzf)'
alias cphash='echo -n "https://app-$(md5 -qs $(git rev-parse --abbrev-ref HEAD)).datadoghq.com" | pbcopy'
alias gri='git rebase --autosquash -i'
alias gbb='gh browse -b $(git branch --show-current)'
alias gpr='gh pr view --web'
alias ezsh='$EDITOR ~/.zshrc.personal && source ~/.zshrc.personal'
alias pr="pnpm run"
alias px="pnpm exec"

# Chckout a specific branch, even if it is untracked
gcor() {
  git fetch -f origin "$1:$1"
  git checkout "$1"
}

# Explore a JSON file using Node.
#
# Usage:
#
#     nq <node expression> <file>
#     nq <file>
#
# Examples:
#
#     # Evaluate a JavaScript expression with `$` substituted for the parsed
#     # `data.json`
#     nq '$.filter(d => !!d).map(d => d.length)' data.json
#
#     # Launch an interactive node REPL with the `$` variable assigned to the
#     # parsed `data.json`
#     nq 'data.json'
#
nq() {
  if [ $# -gt 1 ]; then
    node -e "const $ = JSON.parse(require('fs').readFileSync('$2')); console.log($1)"
  else
    node -i -e "const $ = JSON.parse(require('fs').readFileSync('$1'))"
  fi
}

grin() {
  git rebase --autosquash -i HEAD~$1
}

wip() {
  if [ $# -gt 0 ]; then
    git add -A && git commit --no-gpg-sign --no-verify -m "wip: $1" 
  else
    git add -A && git commit --no-gpg-sign --no-verify -m "wip"
  fi
}

j() {
  if [[ $# -gt 0 ]]; then
    z $1
  else
    zi
  fi
}

tmux-dev() {
  local name="${1:?Usage: tmux-dev <session-name>}"

  tmux new-session -d -s "$name" -n editor
  tmux new-window -t "$name" -n agent
  tmux new-window -t "$name" -n dev
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}

# Open $EDITOR on a fresh temp file, then print the path on stdout.
# Meant for command substitution, e.g.:
#
#     my_command -p "$(etmp)"
#     gh issue create --body-file "$(etmp md)"
#
# Optional first arg is a file extension (no dot) so the editor picks up
# syntax highlighting, e.g. `etmp md`, `etmp json`.
#
# Fails (non-zero exit -> aborts the outer command under `set -e` or when
# the substitution is required) if the editor errors out or the file is
# left empty.
etmp() {
  local ext="${1:+.$1}"
  local file
  file="$(mktemp /tmp/etmp.XXXXXX)" || return 1
  if [[ -n "$ext" ]]; then
    mv "$file" "$file$ext" || { rm -f "$file"; return 1; }
    file="$file$ext"
  fi

  # Attach the editor to the terminal so $(etmp) only captures the path.
  "${EDITOR:-vi}" "$file" </dev/tty >/dev/tty || {
    print -u2 "etmp: editor exited non-zero, aborting"
    rm -f "$file"
    return 1
  }

  if [[ ! -s "$file" ]]; then
    print -u2 "etmp: $file is empty, aborting"
    rm -f "$file"
    return 1
  fi

  print -r -- "$file"
}


# Edit current command with ^J
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^J' edit-command-line

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

autoload -Uz compinit
compinit

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

command -v jj &> /dev/null && source <(COMPLETE=zsh jj)

command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

command -v tv &> /dev/null && eval "$(tv init zsh)"

command -v wt &> /dev/null && eval "$(wt shell-init)"

command -v starship &> /dev/null && eval "$(starship init zsh)"

[ -f ~/.config/zsh/title.zsh ] && source ~/.config/zsh/title.zsh

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

[ -f $HOME/.env ] && source $HOME/.env
