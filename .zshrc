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
alias lss="ls -laGF"
alias v="vim"
alias sv="sudo vim"
alias pacman="sudo pacman"
alias clyde="sudo clyde"
alias tma="tmux attach -d"
alias transmote="transmission-remote"
alias snooze="sudo pm-suspend"
alias cake-ssh="ssh -p4445 chris@cake.mine.nu"
alias cake-sftp="sftp -oPort=4445 chris@cake.mine.nu"

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
setprompt () {
	# load some modules
	autoload -U colors zsh/terminfo # Used in the colour alias below
	colors
	setopt extended_glob prompt_subst

	# make some aliases for the colours: (coud use normal escap.seq's too)
	for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
		eval PR_$color='%{$fg[${(L)color}]%}'
	done
	PR_NO_COLOR="%{$terminfo[sgr0]%}"

	# Check the UID
	if [[ $UID -ge 1000 ]]; then # normal user
		eval PR_USER='${PR_WHITE}%n${PR_NO_COLOR}'
		eval PR_USER_OP='${PR_WHITE}%#${PR_NO_COLOR}'
	elif [[ $UID -eq 0 ]]; then # root
		eval PR_USER='${PR_RED}%n${PR_NO_COLOR}'
		eval PR_USER_OP='${PR_RED}%#${PR_NO_COLOR}'
	fi	

	# Check if we are on SSH or not
	if [[ -n "$SSH_CLIENT"  ||  -n "$SSH2_CLIENT" ]]; then 
		eval PR_HOST='${PR_YELLOW}%M${PR_NO_COLOR}' #SSH
	else 
		eval PR_HOST='${PR_CYAN}%M${PR_NO_COLOR}' # no SSH
	fi
	# set the prompt
	PS1=$'${PR_USER}${PR_CYAN}@${PR_HOST}${PR_BLUE} %~ ${PR_USER_OP} ${PR_WHITE}'
	PS2=$'%_>'
}
setprompt

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
