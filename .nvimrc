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
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-vinegar'
Plugin 'rizzatti/funcoo.vim'
Plugin 'rizzatti/dash.vim'
Plugin 'mattn/webapi-vim'
Plugin 'mattn/gist-vim'
Plugin 'csexton/jekyll.vim'
Plugin 'othree/html5.vim'
Plugin 'groenewege/vim-less'
Plugin 'kien/ctrlp.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mustache/vim-mustache-handlebars'
Plugin 'godlygeek/tabular'
Plugin 'ap/vim-css-color'
Plugin 'ervandew/supertab'
Plugin 'bling/vim-airline'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/syntastic'
Plugin 'rking/ag.vim'
Plugin 'davidhalter/jedi-vim'
Plugin 'chenn/vim-jsdoc'
Plugin 'marijnh/tern_for_vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'plasticboy/vim-markdown'
Plugin 'vim-scripts/YankRing.vim'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'rust-lang/rust.vim'

Plugin 'chriskempson/base16-vim'

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
set laststatus=1

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Support more formats for commentary.vim
autocmd filetype apache set commentstring=#\ %s

" CoffeeScript options
let coffee_compile_vert = 1
let coffee_linter = '/usr/local/share/npm/bin/coffeelint'
au BufNewFile,BufReadPost *.coffee setl shiftwidth=2 expandtab foldlevel=2 foldmethod=indent tw=80 formatoptions+=w
au BufNewFile,BufReadPost *.coffee setfiletype coffee

" CoffeeTags setup
let g:tagbar_iconchars = ['+', '-']
let g:tagbar_left = 1
let g:tagbar_foldlevel = 1
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0
if executable('coffeetags')
  let g:tagbar_type_coffee = {
        \ 'ctagsbin' : 'coffeetags',
        \ 'ctagsargs' : '',
        \ 'kinds' : [
        \ 'f:functions',
        \ 'o:object',
        \ ],
        \ 'sro' : ".",
        \ 'kind2scope' : {
        \ 'f' : 'object',
        \ 'o' : 'object',
        \ }
        \ }
endif

" JS options
au BufNewFile,BufReadPost *.js setl shiftwidth=2 expandtab foldlevel=1 foldmethod=indent tw=80 formatoptions+=w
let g:javascript_conceal_function = "ƒ"
let g:javascript_ignore_javaScriptdoc = 1

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
" let g:airline_detect_whitespace=0

" jedi-vim options
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_on_dot = 0

" Syntastic options
let g:syntastic_html_checkers = ['']

" vim-pandoc options
let g:pandoc#syntax#conceal#use = 0

" Some key mappings
map <C-t> :TagbarToggle<CR>
map <F3> :w !pbcopy<CR><CR>
nnoremap <leader>f :CtrlP<CR>
nnoremap <leader>b :CtrlPBuffer<CR>
set pastetoggle=<F4>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=Source\ Code\ Pro:h15
    set antialias
endif
