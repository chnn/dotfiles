### environment variables
export EDITOR="vim"
export PATH="/usr/local/bin:/usr/bin:$PATH"

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
alias lss="ls"
alias v="vim"
alias sv="sudo vim"
alias pacman="sudo pacman"
alias clyde="sudo clyde"
alias tma="tmux attach -d"

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

### prompt
PROMPT='%n@%m :: %2~ %B$%b '

### key bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "^H" backward-delete-word
# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# for non RH/Debian xterm, can't hurt for RH/DEbian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix

if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
  . startx
  logout
fi

### RVM
# load RVM into shell session as a function (sandboxed home directory goodness
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
