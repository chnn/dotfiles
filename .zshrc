bindkey -e

export EDITOR="vim"
export NOTES="$HOME/Documents/Influx/Notes"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export GPG_TTY=$(tty)

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Python
if command -v pyenv 1>/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# Go
export GOPATH="$HOME/Dev/Go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# rbenv
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# autojump 
[ -f /usr/local/etc/profile.d/autojump.sh ] && source /usr/local/etc/profile.d/autojump.sh
[ -f /etc/profile.d/autojump.zsh ] && source /etc/profile.d/autojump.zsh

# FZF
export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/key-bindings.zsh

j() {
  [ $# -gt 0 ] && cd $(autojump "$*") && return
  local dir
  dir="$(cat ~/.local/share/autojump/autojump.txt | sort -nr | awk '{print $2}' | fzf +s)" && cd "${dir}" || return 1
}

autoload -U colors && colors
autoload -Uz vcs_info
precmd () { vcs_info }
setopt prompt_subst
zstyle ':vcs_info:git*' formats " %{$fg[magenta]%}%b%{$reset_color%}"
PROMPT='%{$fg[blue]%}%3~%{$reset_color%}${vcs_info_msg_0_} $ '

alias e="$EDITOR"
alias f="nnn"
alias nn="cd $NOTES && $EDITOR"
alias dr="cd ~ && fd --ignore-file .searchignore -t d | fzf --print0 | xargs -0 open"
alias fr="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open -R"
alias fe="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 $EDITOR"
alias fo="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open"

alias ls="ls -la -h"
alias dcls="docker container ls -a"
alias b="bundle exec"
alias bs="brew services"
alias m="python manage.py"
alias y="yarn run"
alias nr="yarn run"
alias pe="pipenv run"

alias g='git'
alias gst='git status'
alias gp='git pull'
alias gc='git commit'
alias gcf='git add -A && git commit -v'
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
alias hb='hub browse'

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
