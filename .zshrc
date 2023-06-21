set -o emacs

export EDITOR="nvim"
export SHELL="/bin/zsh"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export NOTES="$HOME/Documents/Dropbox/Notes"
export JOURNAL="$HOME/Documents/Journal"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# JavaScript
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Homebrew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Broot
[ -f ~/.config/broot/launcher/bash/br ] && source ~/.config/broot/launcher/bash/br

# cd
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# # Ruby
# source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh
# source $(brew --prefix)/opt/chruby/share/chruby/auto.sh
# chruby ruby-3.1.3

# FZF
export FZF_DEFAULT_COMMAND="rg --files --sortr=created --hidden --iglob '!.git'"
export FZF_DEFAULT_OPTS='--layout=reverse'

[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh

# Stripe
[ -f ~/.work.zshrc ] && source ~/.work.zshrc

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
alias cat="bat"
alias f="ranger"
alias tma="tmux attach -d || tmux"
alias ns='cd "$NOTES" && $EDITOR && cd -'
alias ezsh="$EDITOR ~/.zshrc && . ~/.zshrc"
alias g='git'
alias gs='git status -sb -uno'
alias gsu='git status -sb'
alias gd='git diff'
alias glo='git log --oneline -n 20'
alias gp='git pull'
alias gca='git add -A && git commit -v'
alias gb='git branch --sort=-committerdate'
alias gcb='git checkout $(git branch --sort=-committerdate | fzf)'
alias gba='git branch -a --sort=-committerdate'
alias gco="git checkout"
alias grp="git rev-parse HEAD"
alias gri='git rebase --autosquash -i'
alias gfu='git add -A && git commit --fixup'
alias gbb='gh browse -b $(git branch --show-current)'
alias gpr='gh pr view --web'
alias yr='yarn run $(cat package.json | jq -r ".scripts | keys[]" | fzf)'
alias pjs="cat package.json | jq '.scripts'"

gprs() {
  gh pr view --web $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

gcopr() {
  gh pr checkout $(gh pr list -L 100 | fzf | sd '^([0-9]+).*' '$1')
}

nj() {
  local filename="$(date '+%F').md"

  if [ $# -gt 0 ]; then
    filename="$(date '+%F') $1.md"
  fi

  cd $JOURNAL

  if test -f "template.md" && ! test -f $filename; then
    cp template.md $filename
  fi

  $EDITOR $filename
  cd -
}

function j() {
  if [[ $# -gt 0 ]]; then
    z $1
  else
    zi
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
