call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'

Plug 'bling/vim-airline'
Plug 'othree/html5.vim'
Plug 'groenewege/vim-less'
Plug 'kien/ctrlp.vim'
Plug 'Jelera/vim-javascript-syntax'
Plug 'mustache/vim-mustache-handlebars'
Plug 'godlygeek/tabular'
Plug 'ap/vim-css-color'
Plug 'scrooloose/syntastic'
Plug 'rking/ag.vim'
Plug 'airblade/vim-gitgutter'
Plug 'Raimondi/delimitMate'
Plug 'mattn/emmet-vim'
Plug 'plasticboy/vim-markdown'
Plug 'editorconfig/editorconfig-vim'
Plug 'Valloric/YouCompleteMe', { 'do': './install.sh' }
Plug 'davidhalter/jedi-vim', { 'for': 'python' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'raichoo/haskell-vim', { 'for': 'haskell' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'marijnh/tern_for_vim', { 'for': 'javascript', 'do': 'npm install' }
Plug 'chenn/vim-jsdoc', { 'for': 'javascript' }
Plug 'tpope/vim-salve', { 'for': 'clojure' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'lervag/vimtex'
Plug 'chriskempson/base16-vim'
Plug 'altercation/vim-colors-solarized'
Plug 'vim-pandoc/vim-pandoc'

call plug#end()

" Necessary to show unicode glyphs
" set encoding=utf-8

" Turn off annoying bell
set visualbell

" Turn on mouse
set mouse=a

" Turn on line numbering
set number

" Set color scheme
set t_Co=256
set background=light
colorscheme solarized

" Set folding options
set foldmethod=indent

" Avoid NeoVim double status line bug
set wildmode=full

" Don't highlight long lines for speed
set synmaxcol=240

" Avoid NeoVim esc bug
set ttimeout
set ttimeoutlen=0

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Reload vimrc when after it's written
augroup myvimrc
    au!
    au BufWritePost .nvimrc,_nvimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC
augroup END

" CtrlP
let g:ctrlp_working_path_mode = 0
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/dist/**
set wildignore+=*/bower_components/**
set wildignore+=*/node_modules/**
set wildignore+=*/docs/**
set wildignore+=*.pyc

" .swp and backup file locations
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp

" vim-airline options
let g:airline_theme='solarized'
let g:airline_left_sep=''
let g:airline_right_sep=''

" jedi-vim options
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_on_dot = 0

" Syntastic options
let g:syntastic_html_checkers = ['']

" emmet options
let g:user_emmet_leader_key = '<leader>e'
let g:emmet_html5 = 1

" vim-pandoc options
let g:pandoc#syntax#conceal#use = 0
let g:pandoc#modules#disabled = ["formatting", "folding"]
