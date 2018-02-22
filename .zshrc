bindkey -e

export TERM="xterm-256color"
export EDITOR="nvim"
export NOTES="$HOME/Documents/Notes"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export GPG_TTY=$(tty)

# Node
export NVM_DIR="$HOME/.nvm"
[ -f /usr/local/opt/nvm/nvm.sh ] && . /usr/local/opt/nvm/nvm.sh

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# TeX
export PATH="/Library/TeX/texbin:$PATH"

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi

# Go
export GOPATH="$HOME/Dev/Go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# autojump
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

alias ls="ls -l -h"
alias n="cd $NOTES && $EDITOR"
alias t="cd $NOTES && $EDITOR t.taskpaper"
alias b="bundle exec"
alias m="python manage.py"
alias pe="pipenv run"
alias e="$EDITOR"
alias f="ranger"
alias p="pass -c"
alias g='git'
alias gst='git status'
alias gp='git pull'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias glg='git log --stat --max-count=10'
alias glgg='git log --graph --max-count=10'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate --color'
alias glog='git log --oneline --decorate --color --graph'
alias gss='git status -s'
alias ga='git add'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
alias gmc='git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -10'

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY  # append history to history file as opposed to overwriting it
setopt INC_APPEND_HISTORY  # append history incrementally
setopt SHARE_HISTORY  # share history
autoload -U compinit; compinit -i

PROMPT="%2~ $ "
