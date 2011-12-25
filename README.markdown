Here be config files...
-----------------------

They're from my macbook, but I share them with some linux machines too. Please use anything you'd like. I put them here for my own benefit, but if you want to use them and have questions I'm happy to help.

### Configs for:

* vim
* zsh
* tmux
* X11
* xmonad
* ncmpcpp
* a few others

#### Notes about Vim dotfiles

The Vim configuration under `.vim/` is the most complicated, but I try to keep it simple. I use [vundle](https://github.com/gmarik/vundle) to manage plugins. 

"Vundles" are specified in `.vimrc`. Once you've copied or symlinked `.vim/` and `.vimrc` to your home directory, open vim and run:

    :BundleInstall

vundle should take care of everything for you. Some plugins require a little extra work. Check the `README` in [Command-T](https://github.com/wincent/Command-T) to see how to set it up (it requires vim with ruby enabled.)
