bindkey -e

export TERM="xterm-256color"
export EDITOR="nvim"
export SHELL="/bin/zsh"
export PATH="/usr/local/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

# export PATH="/usr/local/texlive/2016/bin/x86_64-darwin:$PATH"

# export PATH="$(yarn global bin):$PATH"

# export HOMEBREW_GITHUB_API_TOKEN="fa9e409b28c78229a7e0656eb0b2ed23268b3de9"

# export GOPATH=$HOME/Dev/go
# export PATH="$GOPATH/bin:$GOBIN:$PATH"

# export NVM_DIR=~/.nvm
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
# if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# export WORKON_HOME=$HOME/.virtualenvs
# export PROJECT_HOME=$HOME/Dev
# source $HOME/.local/bin/virtualenvwrapper.sh

source /usr/share/autojump/autojump.zsh

function cd {
    builtin cd $@
    pwd > ~/.last_dir
}

if [ -f ~/.last_dir ]
    then cd `cat ~/.last_dir`
fi

alias ls="ls -l"
alias t="cd ~/Dropbox/Notes && nvim t.md"
alias tma="tmux attach -d"
alias nombom='echo "\n (╯°□°）╯︵ ┻━┻ \n" && npm cache clear && bower cache clean && rm -rf node_modules bower_components && npm install && bower install'
alias b="bundle exec"
alias m="python manage.py"
alias e="$EDITOR"
alias g='git'
alias gst='git status'
alias gp='git pull'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias glg='git log --stat --max-count=10'
alias glgg='git log --graph --max-count=10'
alias glgga='git log --graph --decorate --all'
alias glo='git log --oneline --decorate --color'
alias glog='git log --oneline --decorate --color --graph'
alias gss='git status -s'
alias ga='git add'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY  # append history to history file as opposed to overwriting it
setopt INC_APPEND_HISTORY  # append history incrementally
setopt SHARE_HISTORY  # share history
autoload -U compinit; compinit -i

PROMPT="%~ $ "
