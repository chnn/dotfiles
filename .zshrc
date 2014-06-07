bindkey -e
export EDITOR="vim"
export PATH="/usr/local/share/npm/bin:/usr/local/bin:$HOME/.rbenv/bin:$PATH"

export GOPATH=$HOME/.go

# export WORKON_HOME=$HOME/.virtualenvs
# source /usr/local/bin/virtualenvwrapper.sh

# eval "$(rbenv init -)"

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
alias v="vim"
alias sv="sudo vim"
alias tma="tmux attach -d"
alias sshtunnel="sudo networksetup -setsocksfirewallproxy Wi-Fi localhost 4040 && ssh -D 4040 -C -N pi"
alias sshtunneloff="sudo networksetup -setsocksfirewallproxystate Wi-Fi off"
alias rsync-writing="rsync -rP --delete ./_site/ precipice:/home/precipice/sites/home/public_html/writing"

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
