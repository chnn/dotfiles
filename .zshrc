bindkey -e

export EDITOR="nvim"
export NOTES="$HOME/Documents/Notes"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export GPG_TTY=$(tty)

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

export INFLUX_TOKEN="Q2iTPyFjsxWOlb0p4PsZWUrLyd66oyyFLXiAjF_g82YGK5cXGlpjjipwHfzRDG7fFuN1IvangAM1mK9k3443Og=="

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
[ -s "$VOLTA_HOME/load.sh" ] && . "$VOLTA_HOME/load.sh"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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
export FZF_DEFAULT_COMMAND='rg --files'
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
alias ls="ls -la -h"
alias f="nnn"
alias nn="cd $NOTES && $EDITOR"
alias dr="cd ~ && fd --ignore-file .searchignore -t d | fzf --print0 | xargs -0 open"
alias fr="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open -R"
alias fe="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 $EDITOR"
alias fo="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open"
alias ezsh="$EDITOR ~/.zshrc && source ~/.zshrc"

alias b="bundle exec"
alias bs="brew services"
alias m="source .env && mix"
alias y="yarn run"
alias pe="pipenv run"
alias sd="systemctl"
alias sdu="systemctl --user"

alias d="docker"
alias dc="docker container"
alias di="docker image"

alias g='git'
alias gst='git status -sb'
alias gca='git add -A && git commit -v'
alias gb='git branch --sort=-committerdate'
alias gba='git branch -a'
alias gco="git checkout"
alias glg='git log --stat --max-count=10'
alias glgg='git log --graph --max-count=10'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate --color'
alias glog='git log --oneline --decorate --color --graph'
alias hb='hub browse'
alias wipf="git add -A && git commit --no-gpg-sign --fixup HEAD"

wip() {
  [ $# -gt 0 ] && git add -A && git commit --no-gpg-sign -m "wip: $1" && return
  git add -A && git commit --no-gpg-sign -m "wip"
}

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
