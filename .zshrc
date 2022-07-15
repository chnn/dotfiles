set -o emacs

export EDITOR="nvim"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export TERM="screen-256color"
export NOTES="$HOME/Documents/Notes"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# JavaScript
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# autojump
export AUTOJUMP_DB="$HOME/Library/autojump/autojump.txt"
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh # macOS

# FZF
export FZF_DEFAULT_COMMAND='rg --files --hidden'
[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh

# Stripe
[ -f "$HOME/.stripe.zsh" ] && . "$HOME/.stripe.zsh"

# Edit current command with ^J
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

# Alias'
alias e="$EDITOR"
alias ls="exa -l"
alias f="ranger"
alias tma="tmux attach -d || tmux"
alias ns='cd "$NOTES" && $EDITOR'
alias dr="cd ~ && fd --ignore-file .searchignore -t d | fzf --print0 | xargs -0 open"
alias fr="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open -R"
alias fe="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 $EDITOR"
alias fo="cd ~ && fd --ignore-file .searchignore | fzf --print0 | xargs -0 open"
alias ezsh="$EDITOR ~/.zshrc && . ~/.zshrc"
alias pjs="cat package.json | jq '.scripts'"
alias g='git'
alias gst='git status -sb'
alias glo='git log --oneline -n 20'
alias glon='git log --oneline -n 10'
alias gp='git pull'
alias glo='git log --oneline'
alias gca='git add -A && git commit -v'
alias gb='git branch --sort=-committerdate'
alias gcb='git checkout $(git branch --sort=-committerdate | fzf)'
alias gba='git branch -a --sort=-committerdate'
alias gco="git checkout"
alias gplease='git push --force-with-lease'
alias gri='git rebase --autosquash -i'
alias gfu='git add -A && git commit --fixup'
alias gbb='gh browse -b $(git branch --show-current)'
alias hb='hub browse'
alias hpr=$'hub pr show $(hub pr list | fzf | sd \'\w*#(\d+).*\' \'$1\')'
alias fyr='yarn run $(cat package.json | jq -r ".scripts | keys[]" | fzf)'

gprs() {
  gh pr view --web $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

gcopr() {
  gh pr checkout $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

j() {
  [ $# -gt 0 ] && cd $(autojump "$*") && return
  local dir
  dir="$(cat $AUTOJUMP_DB | sort -nr | awk '{print $2}' | fzf +s)" && cd "${dir}" || return 1
}

nj() {
  if [ $# -gt 0 ]; then
    cd $JOURNAL && $EDITOR "$(date '+%F') $1.md"
  else
    cd $JOURNAL && $EDITOR "$(date '+%F').md"
  fi
}

# Explore a JSON file using Node.
#
# Usage:
#
#     nq <node expression> <file>
#     nq <file>
#
# Examples:
#
#     # Evaluate a JavaScript expression with `$` substituted for the parsed
#     # `data.json`
#     nq '$.filter(d => !!d).map(d => d.length)' data.json
#
#     # Launch an interactive node REPL with the `$` variable assigned to the
#     # parsed `data.json`
#     nq 'data.json'
#
nq() {
  if [ $# -gt 1 ]; then
    node -e "const $ = JSON.parse(require('fs').readFileSync('$2')); console.log($1)"
  else
    node -i -e "const $ = JSON.parse(require('fs').readFileSync('$1'))"
  fi
}

grin() {
  git rebase --autosquash -i HEAD~$1
}

wip() {
  if [ $# -gt 0 ]; then
    git add -A && git commit --no-gpg-sign -m "wip: $1" 
  else
    git add -A && git commit --no-gpg-sign -m "wip"
  fi
}

mov2mp4() {
  ffmpeg -i "$1" -vcodec h264 -acodec aac "$(echo $1 | rev | cut -c 5- | rev).mp4"
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
