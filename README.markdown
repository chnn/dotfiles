Here be config files...
-----------------------

They're from my macbook, but I share them with some linux machines too. Please use anything you'd like. I put them here for my own benefit, but if you want to use them and have questions I'm happy to help.

### Configs for:

* nvim
* zsh
* tmux
* X11
* xmonad
* ncmpcpp
* a few others

#### Notes about Vim dotfiles

The NeoVim configuration under `.nvim/` is the most complicated, but I try to keep it simple. I use [vundle](https://github.com/gmarik/vundle) to manage plugins.

To use vundle, make sure you update the submodules in your local repo so vundle gets downloaded:

    $ git submodule init
    $ git submodule update

This will clone vundle to .nvim/bundle/vundle. Now copy .nvim/ and .nvimrc to your home directory, then run `:PluginInstall` in vim.

This will download the latest version of the plugins specified in .vimrc.

You should copy and not symlink the .nvim/ directory (though symlinking .nvimrc is fine.) Otherwise, you'll have a bunch of submodules in .nvim/bundle that vundle has downloaded that won't actually be in .gitmodules. Icky.
