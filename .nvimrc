" filename: .vimrc
" author: Chris Henn

" Set up Vundle
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-vinegar'
Plugin 'tpope/vim-sleuth'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-repeat'
Plugin 'bling/vim-airline'
Plugin 'rizzatti/funcoo.vim'
Plugin 'rizzatti/dash.vim'
Plugin 'othree/html5.vim'
Plugin 'groenewege/vim-less'
Plugin 'kien/ctrlp.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mustache/vim-mustache-handlebars'
Plugin 'godlygeek/tabular'
Plugin 'ap/vim-css-color'
Plugin 'ervandew/supertab'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/syntastic'
Plugin 'rking/ag.vim'
Plugin 'davidhalter/jedi-vim'
Plugin 'chenn/vim-jsdoc'
Plugin 'marijnh/tern_for_vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'plasticboy/vim-markdown'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'rust-lang/rust.vim'
Plugin 'raichoo/haskell-vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'Raimondi/delimitMate'
Plugin 'mattn/emmet-vim'

Plugin 'chriskempson/base16-vim'
Plugin 'altercation/vim-colors-solarized'

call vundle#end()
filetype plugin indent on

" Necessary to show unicode glyphs
set encoding=utf-8

" Turn off annoying bell
set visualbell

" Turn on mouse
set mouse=a

" Turn on line numbering
set number

" Highlight all matches when searching
set hlsearch

" Syntax highlighting
syntax enable

" Allow backspacing auto-indentation, line breaks, previous edits
set backspace=indent,eol,start

" Set color scheme
set background=dark
colorscheme base16-tomorrow

" Set tab/spaces options
set ai et sw=4 sts=4 ts=4

" Set folding options
set foldmethod=indent

set wildmenu

" Always show statusbar
set laststatus=2

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" JS options
" au BufNewFile,BufReadPost *.js setl shiftwidth=2 expandtab foldlevel=1 foldmethod=indent tw=80 formatoptions+=w
" let g:javascript_conceal_function = "ƒ"
" let g:javascript_ignore_javaScriptdoc = 1

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
let g:airline_theme='simple'
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

" Some key mappings
map <F3> :w !pbcopy<CR><CR>
set pastetoggle=<F4>
nnoremap <leader>f :CtrlP<CR>
nnoremap <leader>b :CtrlPBuffer<CR>
nnoremap <D-p>f :CtrlP<CR>
