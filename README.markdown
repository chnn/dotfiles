Here be config files...
-----------------------

### NeoVim

Uses [vim-plug](https://github.com/junegunn/vim-plug).

1. `pip3 install neovim neovim-remote`
1. Ensure `nvr` in path (add `export PATH="$HOME/.local/bin:$PATH"` to shell profile)
1. Install `vim-plug` by running `curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`
1. Link `.config/nvim/init.vim` to `$HOME/.config/nvim/init.vim`
1. Run `:PlugInstall` inside NeoVim
