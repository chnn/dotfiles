Here be config files...
-----------------------

### Vim

Uses [vim-plug](https://github.com/junegunn/vim-plug).

1. Install `vim-plug`
1. Link `.vimrc` to `$HOME/.vimrc`
1. Run `:PlugInstall` inside Vim
1. Vim must be launched with `vim --servername [SOMETHING]` for vimtex callbacks to work. Here's a handy script:
   ```
   #!/bin/sh
   exec /usr/bin/vim --servername vim "$@"
   ```
