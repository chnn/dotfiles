" filename: .vimrc
" author: Chris Henn

" Set up vundle
set nocompatible
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'

" List bundles
Bundle 'tpope/vim-fugitive'
Bundle 'scrooloose/nerdtree'
Bundle 'csexton/jekyll.vim'
Bundle 'tpope/vim-commentary'
Bundle 'scrooloose/syntastic'
Bundle 'skammer/vim-css-color'
Bundle 'othree/html5.vim'
Bundle 'groenewege/vim-less'
Bundle 'tpope/vim-markdown'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-liquid'
Bundle 'godlygeek/tabular'
Bundle 'nelstrom/vim-blackboard'
Bundle 'vim-scripts/SuperTab-continued.'
Bundle 'kien/ctrlp.vim'
Bundle 'pangloss/vim-javascript'
Bundle 'kchmck/vim-coffee-script'
Bundle 'vim-indent-object'
Bundle 'nono/vim-handlebars'
Bundle 'wlangstroth/vim-haskell'
Bundle 'closetag.vim'
" Bundle 'vim-ruby/vim-ruby'
" Bundle 'tpope/vim-abolish'
" Bundle 'tpope/vim-rails'
" Bundle 'Jinja'
" Bundle 'majutsushi/tagbar'
" Bundle 'aaronj1335/underscore-templates.vim'
" Bundle 'tpope/vim-unimpaired'
" Bundle 'tobinvanpelt/vim-semicolon'
" Bundle 'tpope/vim-haml'
" Bundle 'Lokaltog/powerline'
" Bundle 'vim-scripts/Rainbow-Parenthesis'
" Bundle 'briandoll/change-inside-surroundings.vim'
" Bundle 'henrik/vim-ruby-runner'
" Bundle 'YankRing.vim'
" Bundle 'git://git.wincent.com/command-t.git'

" Re-enable file detection after vundle has been called
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
syntax on

" Background is dark
set background=dark

" Set color scheme
colorscheme vimbrant

" Set tab/spaces options
set ai et sw=4 sts=4 ts=4

" Set folding options
set foldmethod=indent

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Set backup directory for files being edited
set backupdir=~/.vim/backup

" Get permission to edit file
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" Remembers last position in file
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" Set path to Jekyll blog for Jekyll.vim
let g:jekyll_path = "~/Dev/chenn.github.com/"

" Highlight Jekyll post YAML content correctly
execute "autocmd BufNewFile,BufRead " . g:jekyll_path . "/* syn match jekyllYamlFrontmatter /\\%^---\\_.\\{-}---$/ contains=@Spell"

" Support more formats for commentary.vim
autocmd filetype apache set commentstring=#\ %s

" Coffeescript options
let coffee_compiler = '/usr/local/share/npm/bin/coffee'
let coffee_linter = '/usr/local/share/npm/bin/coffeelint'
let coffee_make_options = ''
au BufNewFile,BufReadPost *.coffee setl shiftwidth=2 expandtab foldlevel=2 foldmethod=indent textwidth=80
" au BufWritePost *.coffee silent CoffeeMake

" Start CtrlP in last used mode
let g:ctrlp_cmd = 'CtrlPLastMode'

" Commands to hide JavaScript files in CtrlP
command! ShowJS let g:ctrlp_custom_ignore= '\.pyc$' | :ClearAllCtrlPCaches
command! HideJS let g:ctrlp_custom_ignore= '\.js$\|\.pyc$' | :ClearAllCtrlPCaches

" Ignore certain checks in syntastic
let g:syntastic_python_checker_args='--ignore=E70'

" For markdown documents
command! -nargs=* Wrap set wrap linebreak nolist

" Some key mappings
map <S-n> :NERDTreeToggle<CR>
map <S-y> :YRShow<CR>
map <S-t> :Tab /=<CR>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=M+\ 1mn\ light:h14
    set background=dark
    colorscheme Tomorrow-Night
    set antialias
    set spell
endif
