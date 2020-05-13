set -o emacs

export EDITOR="nvim"
export PAGER="bat -p"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export GPG_TTY=$(tty)

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Stripe
[ -f "$HOME/.stripe.zsh" ] && . "$HOME/.stripe.zsh"

# JavaScript
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
[ -s "$VOLTA_HOME/load.sh" ] && . "$VOLTA_HOME/load.sh"

# Go
export GOPATH="$HOME/stripe/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# autojump 
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
[ -f /etc/profile.d/autojump.zsh ] && . /etc/profile.d/autojump.zsh

# FZF
export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && . /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && . /usr/share/fzf/key-bindings.zsh

# Edit current command with ^E
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^J' edit-command-line

# Prompt
autoload -U colors && colors
autoload -Uz vcs_info
precmd () { vcs_info }
setopt prompt_subst
zstyle ':vcs_info:git*' formats "%F{magenta}%b%f "
PROMPT='%F{blue}%3~%f ${vcs_info_msg_0_}$ '

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Alias'
alias e="$EDITOR"
alias ls="exa -lab --time-style=iso"
alias f="ranger"
alias t="cd '$NOTES' && $EDITOR '$NOTES/todo.md'"
alias tma="tmux attach -d || tmux"
alias ns='cd "$NOTES" && $EDITOR'
alias dr="cd ~ && fd --ignore-file .searchignore -t d | fzf --print0 | xargs -0 open"
alias fr="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open -R"
alias fe="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 $EDITOR"
alias fo="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open"
alias ezsh="$EDITOR ~/.zshrc && . ~/.zshrc"
alias b="bundle exec"
alias bs="brew services"
alias m="python manage.py"
alias y="yarn run"
alias pe="pipenv run"
alias d="docker"
alias dc="docker container"
alias di="docker image"
alias g='git'
alias gst='git status -sb'
alias gp='git pull'
alias gca='git add -A && git commit -v'
alias gb='git branch --sort=-committerdate'
alias gcb='git checkout $(git branch --sort=-committerdate | fzf)'
alias gba='git branch -a'
alias gco="git checkout"
alias glg='git log --stat --max-count=10'
alias glgg='git log --graph --max-count=10'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate --color'
alias glog='git log --oneline --decorate --color --graph'
alias gpuoh='git push -u origin head'
alias gplease='git push --force-with-lease'
alias hb='hub browse'
alias hpr=$'hub pr show $(hub pr list | fzf | sd \'\w*#(\d+).*\' \'$1\')'
alias sit='echo $(date +"%Y-%m-%d %H:%M"), sit >> $NOTES/transitions.md'
alias stand='echo $(date +"%Y-%m-%d %H:%M"), stand >> $NOTES/transitions.md'
alias pjs="cat package.json | jq '.scripts'"

grbi() {
  git rebase -i HEAD~$1
}

wip() {
  if [ $# -gt 0 ]; then
    git add -A && git commit --no-gpg-sign -m "wip: $1" 
  else
    git add -A && git commit --no-gpg-sign -m "wip"
  fi
}

# Convert an input file to a GIF. Requires `ffmpeg` and `gifsicle` to be
# installed (use Homebrew).
#
# Example:
#
#     mov2gif myscreenrecording.mov
#
mov2gif() {
  ffmpeg -i "$1" -r 15 -f gif - | gifsicle > "$(echo $1 | rev | cut -c 5- | rev).gif"
}

# Requires `trash` to be installed (use brew)
movs2gifs() {
  cd ~/Desktop
  for f in *.mov
  do
    mov2gif "$f"
    trash "$f"
  done
  cd -
}

mov2mp4() {
  ffmpeg -i "$1" -vcodec h264 "$(echo $1 | rev | cut -c 5- | rev).mp4"
}

j() {
  [ $# -gt 0 ] && cd $(autojump "$*") && return
  local dir
  dir="$(cat ~/Library/autojump/autojump.txt | sort -nr | sd '\d+\.\d+\s+(.*)' '$1' | fzf +s)" && cd "${dir}" || return 1
}
