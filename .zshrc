set -o emacs

export EDITOR="nvim"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export NOTES="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes"
export JOURNAL="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Journal"

# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# Homebrew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Television
autoload -Uz compinit
compinit
eval "$(tv init zsh)"

# zoxide
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# Edit current command with ^J
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^J' edit-command-line

# Prompt
autoload -U colors && colors
setopt prompt_subst
PROMPT='%F{blue}%3~%f $ '

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Aliases
alias e="$EDITOR"
alias ls="ls -l"
alias cat="bat"
alias f="ranger"
alias tma="tmux attach -d || tmux"
alias ns='cd "$NOTES" && $EDITOR && cd -'
alias ezsh="$EDITOR ~/.zshrc && . ~/.zshrc"
alias g='git'
alias gs='git status -sb -uno'
alias gsu='git status -sb'
alias gd='git diff'
alias glo='git log --oneline -n 20'
alias gp='git pull'
alias gca='git add -A && git commit -v'
alias gb='git branch --sort=-committerdate'
alias gcb='git checkout $(git branch --sort=-committerdate | fzf)'
alias gba='git branch -a --sort=-committerdate'
alias gco="git checkout"
alias grp="git rev-parse HEAD"
alias gri='git rebase --autosquash -i'
alias gfu='git add -A && git commit --fixup'
alias gbb='gh browse -b $(git branch --show-current)'
alias gpr='gh pr view --web'
alias yr='yarn run $(cat package.json | jq -r ".scripts | keys[]" | fzf)'
alias pjs="cat package.json | jq '.scripts'"
alias pr="pnpm run"
alias px="pnpm exec"

port() {
  sudo lsof -iTCP -sTCP:LISTEN -n -P | awk 'NR>1 {print $9, $1, $2}' | sed 's/.*://' | while read port process pid; do echo "Port $port: $(ps -p $pid -o command= | sed 's/^-//') (PID: $pid)"; done | sort -n
}

gprs() {
  gh pr view --web $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

gcopr() {
  gh pr checkout $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

nj() {
  local filename="$(date '+%F').md"

  if [ $# -gt 0 ]; then
    filename="$(date '+%F') $1.md"
  fi

  cd $JOURNAL

  if test -f "template.md" && ! test -f $filename; then
    cp template.md $filename
  fi

  $EDITOR $filename
  cd -
}

function j() {
  if [[ $# -gt 0 ]]; then
    z $1
  else
    zi
  fi
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
    git add -A && git commit --no-gpg-sign -m "wip: $1" 
  else
    git add -A && git commit --no-gpg-sign -m "wip"
  fi
}

wn() {
  git fetch
  git worktree add -b "chnn/$1" "../web-ui-$1" origin/preprod
  cd "../web-ui-$1"
  ln -s ../web-ui/.nvim.lua ./.nvim.lua
  yarn
}
