### environment variables
export EDITOR="vim"
export PATH="/usr/local/bin:/usr/bin:/usr/local/share/python:$HOME/.rbenv/bin:/usr/local/share/npm/bin:$PATH"
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Dev
source /usr/local/bin/virtualenvwrapper.sh

### history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY #append history to history file as opposed to overwriting it
setopt INC_APPEND_HISTORY #append history incrementally
setopt SHARE_HISTORY #share history

### colored man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

### alias'
alias ls="ls -laG"
alias v="vim"
alias sv="sudo vim"
alias tma="tmux attach -d"
alias sshtunnel="ssh -fND 4711 -p" # sshtunnel [port] [server] --- starts tunnel on local port 4711
alias jk="jekyll --server --auto"
alias rsync-chenn="rsync -rP ./_site/ abbey:/srv/http/chenn.io/public/log/"
alias qemu="qemu-system-x86_64"

### tab completion
autoload -U compinit; compinit
# List of completers to use
zstyle ":completion:*" completer _complete _match _approximate
# Allow approximate
zstyle ":completion:*:match:*" original only
zstyle ":completion:*:approximate:*" max-errors 1 numeric
# Selection prompt as menu
zstyle ":completion:*" menu select=1
# Menu selection for PID completion
zstyle ":completion:*:*:kill:*" menu yes select
zstyle ":completion:*:kill:*" force-list always
zstyle ":completion:*:processes" command "ps -au$USER"
zstyle ":completion:*:*:kill:*:processes" list-colors "=(#b) #([0-9]#)*=0=01;32"
# Don't select parent dir on cd
zstyle ":completion:*:cd:*" ignore-parents parent pwd
# Complete with colors
zstyle ":completion:*" list-colors ""

# Prompt
PROMPT='%n@%m %2~ %B$%b '

# rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
