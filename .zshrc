# environment
export EDITOR="vim"
export PATH="/usr/local/bin:$PATH"
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Dev
source /usr/local/bin/virtualenvwrapper.sh


# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY  # append history to history file as opposed to overwriting it
setopt INC_APPEND_HISTORY  # append history incrementally
setopt SHARE_HISTORY  # share history


# prompt
autoload -U colors && colors
PROMPT="%n@%{$fg[yellow]%}%m%{$reset_color%} %~ $ "


# completion
autoload -U compinit; compinit
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


# alias'
alias ls="ls -laG"
alias v="vim"
alias sv="sudo vim"
alias tma="tmux attach -d"
alias sshtunnel="ssh -fND 4711 -p" # sshtunnel [port] [server] --- starts tunnel on local port 4711
alias rsync-chenn="rsync -rP ./_site/ abbey:/srv/http/chenn.io/public/log/"
alias rsync-music="rsync -avzP --delete ~/Music/iTunes/iTunes\ Media/Music /Volumes/Backup\ Drive/backup-chris/Music"
alias qemu="qemu-system-x86_64"
