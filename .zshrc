bindkey -e
export TERM="xterm-256color"
export EDITOR="nvim"
export PATH="/usr/local/bin:$PATH"
export SHELL="/bin/zsh"
export RAMDISK_DISABLED=true

export GOPATH=$HOME/.go

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# export WORKON_HOME=$HOME/.virtualenvs
# source /usr/local/bin/virtualenvwrapper.sh

export ANSIBLE_NOCOWS=1

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY  # append history to history file as opposed to overwriting it
setopt INC_APPEND_HISTORY  # append history incrementally
setopt SHARE_HISTORY  # share history

autoload -U colors && colors
PROMPT="%n@%{$fg[blue]%}%m%{$reset_color%} %~ $ "

autoload -U compinit; compinit -i
zstyle ":completion:*" completer _complete _match _approximate
zstyle ":completion:*:match:*" original only
zstyle ":completion:*:approximate:*" max-errors 1 numeric
zstyle ":completion:*" menu select=1
zstyle ":completion:*:*:kill:*" menu yes select
zstyle ":completion:*:kill:*" force-list always
zstyle ":completion:*:processes" command "ps -au$USER"
zstyle ":completion:*:*:kill:*:processes" list-colors "=(#b) #([0-9]#)*=0=01;32"
zstyle ":completion:*:cd:*" ignore-parents parent pwd
zstyle ":completion:*" list-colors ""

alias ls="ls -lahG"
alias v="nvim"
alias sv="sudo nvim"
alias tma="tmux attach -d"
alias sshtunnel="sudo networksetup -setsocksfirewallproxy Wi-Fi localhost 4040 && ssh -D 4040 -C -N pi"
alias sshtunneloff="sudo networksetup -setsocksfirewallproxystate Wi-Fi off"
alias rsync-writing="rsync -rP --delete ./_site/ cloudsrest:/home/cloudsrest/writing/public_html"
alias nombom='echo "\n (╯°□°）╯︵ ┻━┻ \n" && npm cache clear && bower cache clean && rm -rf node_modules bower_components && npm install && bower install'

function nom() {
  if [ -z "$1" ]; then
    rm -rf node_modules && npm cache clear && npm i
    return
  fi

  `npm $@`
}

alias g='git'
compdef g=git
alias gst='git status'
compdef _git gst=git-status
alias gl='git pull'
compdef _git gl=git-pull
alias gc='git commit'
compdef _git gc=git-commit
alias gco='git checkout'
compdef _git gco=git-checkout
alias gb='git branch'
compdef _git gb=git-branch
alias gba='git branch -a'
compdef _git gba=git-branch
alias glg='git log --stat --max-count=10'
compdef _git glg=git-log
alias glgg='git log --graph --max-count=10'
compdef _git glgg=git-log
alias glgga='git log --graph --decorate --all'
compdef _git glgga=git-log
alias glo='git log --oneline --decorate --color'
compdef _git glo=git-log
alias glog='git log --oneline --decorate --color --graph'
compdef _git glog=git-log
alias gss='git status -s'
compdef _git gss=git-status
alias ga='git add'
compdef _git ga=git-add
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'

ulimit -n 2048


###-begin-npm-completion-###
#
# npm command completion script
#
# Installation: npm completion >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: npm completion > /usr/local/etc/bash_completion.d/npm
#

COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
COMP_WORDBREAKS=${COMP_WORDBREAKS/@/}
export COMP_WORDBREAKS

if type complete &>/dev/null; then
  _npm_completion () {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           npm completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F _npm_completion npm
elif type compdef &>/dev/null; then
  _npm_completion() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 npm completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _npm_completion npm
elif type compctl &>/dev/null; then
  _npm_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       npm completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K _npm_completion npm
fi
###-end-npm-completion-###
