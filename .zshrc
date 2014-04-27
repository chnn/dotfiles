export EDITOR="vim"
bindkey -e

export PATH="/usr/local/share/npm/bin:/usr/local/bin:$HOME/.rbenv/bin:$PATH"

export GOPATH=$HOME/.go

export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh

eval "$(rbenv init -)"

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

alias ls="ls -laG"
alias v="vim"
alias sv="sudo vim"
alias tma="tmux attach -d"
alias sshtunnel="sudo networksetup -setsocksfirewallproxy Wi-Fi localhost 4040 && ssh -D 4040 -C -N pi"
alias sshtunneloff="sudo networksetup -setsocksfirewallproxystate Wi-Fi off"
alias rsync-writing="rsync -rP --delete ./_site/ precipice:/home/precipice/sites/home/public_html/writing"
