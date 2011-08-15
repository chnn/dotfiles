Here be config files...
-----------------------

They're from my macbook, but I share them with some linux machines too. Please use anything you'd like. 

### Configs for:

* vim
* zsh
* tmux
* X11
* xmonad
* ncmpcpp
* a few others

#### Notes about Vim dotfiles

The Vim configuration under `.vim/` is little more complicated. If the plugins under `.vim/bundle/` (which uses pathogen by the way) don't show up, run:

	git submodule init

then

	git submodule update

A few plugins may require extra steps. The super awesome command-t plugin requires you to `rake make` among other things. Check the README's if something isn't working.
