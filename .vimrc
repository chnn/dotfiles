" filename: .vimrc
" author: Chris Henn

" Set up Vundle
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'csexton/jekyll.vim'
Plugin 'tpope/vim-commentary'
Plugin 'othree/html5.vim'
Plugin 'groenewege/vim-less'
Plugin 'tpope/vim-surround'
Plugin 'kien/ctrlp.vim'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'mustache/vim-mustache-handlebars'
Plugin 'godlygeek/tabular'
Plugin 'ap/vim-css-color'
Plugin 'ervandew/supertab'
Plugin 'bling/vim-airline'
Plugin 'tpope/vim-unimpaired'
Plugin 'tpope/vim-vinegar'
Plugin 'jiangmiao/auto-pairs'
Plugin 'majutsushi/tagbar'
Plugin 'rizzatti/funcoo.vim'
Plugin 'rizzatti/dash.vim'
Plugin 'scrooloose/syntastic'
Plugin 'rking/ag.vim'
Plugin 'davidhalter/jedi-vim'

Plugin 'goatslacker/mango.vim'
Plugin 'jellybeans.vim'
Plugin 'chriskempson/base16-vim'
Plugin 'altercation/vim-colors-solarized'

" Plugin 'fatih/vim-go'
" Plugin 'reedes/vim-pencil'
" Plugin 'reedes/vim-wordy'
" Plugin 'vim-indent-object'
" Plugin 'jnwhiteh/vim-golang'
" Plugin 'airblade/vim-gitgutter'
" Plugin 'wlangstroth/vim-haskell'
" Plugin 'Raimondi/delimitMate'
" Plugin 'scrooloose/nerdtree'
" Plugin 'mhinz/vim-signify'
" Plugin 'xoria256.vim'
" Plugin 'tpope/vim-liquid'
" Plugin 'tobinvanpelt/vim-semicolon'
" Plugin 'vim-ruby/vim-ruby'
" Plugin 'tpope/vim-abolish'
" Plugin 'tpope/vim-rails'
" Plugin 'Jinja'
" Plugin 'majutsushi/tagbar'
" Plugin 'aaronj1335/underscore-templates.vim'
" Plugin 'tpope/vim-haml'
" Plugin 'Lokaltog/powerline'
" Plugin 'vim-scripts/Rainbow-Parenthesis'
" Plugin 'briandoll/change-inside-surroundings.vim'
" Plugin 'henrik/vim-ruby-runner'
" Plugin 'YankRing.vim'
" Plugin 'git://git.wincent.com/command-t.git'

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

" Set color scheme
set background=dark
colorscheme base16-twilight

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

" Support more formats for commentary.vim
autocmd filetype apache set commentstring=#\ %s

" CoffeeScript options
let coffee_compiler = '/usr/local/share/npm/bin/coffee'
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

" Markdown options
au BufNewFile,BufReadPost *.markdown setl wrap linebreak textwidth=0 spell

" Reload vimrc when after it's written
augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC
augroup END

" CtrlP
let g:ctrlp_working_path_mode = 0
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/dist/**
set wildignore+=*/bower_componenets/**
set wildignore+=*/node_modules/**
set wildignore+=*.pyc

" .swp and backup file locations
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp

" vim-airline options
let g:airline_detect_whitespace=0
let g:airline_theme='simple'
let g:airline_left_sep=''
let g:airline_right_sep=''

" jedi-vim options
let g:jedi#use_tabs_not_buffers = 0
let g:jedi#popup_on_dot = 0

" Syntastic options
let g:syntastic_html_checkers = ['']

" Some key mappings
map <C-t> :TagbarToggle<CR>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=Source\ Code\ Pro:h15
    set antialias
endif
