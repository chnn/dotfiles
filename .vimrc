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
Bundle 'csexton/jekyll.vim'
Bundle 'tpope/vim-commentary'
Bundle 'othree/html5.vim'
Bundle 'groenewege/vim-less'
Bundle 'tpope/vim-surround'
Bundle 'kien/ctrlp.vim'
Bundle 'pangloss/vim-javascript'
Bundle 'kchmck/vim-coffee-script'
Bundle 'vim-indent-object'
Bundle 'nono/vim-handlebars'
Bundle 'wlangstroth/vim-haskell'
Bundle 'skammer/vim-css-color'
Bundle 'godlygeek/tabular'
Bundle 'vim-scripts/SuperTab-continued.'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-unimpaired'
Bundle 'mileszs/ack.vim'
Bundle 'baskerville/bubblegum'
Bundle 'goatslacker/mango.vim'
Bundle 'jnwhiteh/vim-golang'
Bundle 'noahfrederick/vim-hemisu'
Bundle 'jellybeans.vim'
Bundle 'chriskempson/base16-vim'
Bundle 'tpope/vim-vinegar'
Bundle 'scrooloose/syntastic'
Bundle 'closetag.vim'
Bundle 'jiangmiao/auto-pairs'
Bundle 'majutsushi/tagbar'
" Bundle 'Raimondi/delimitMate'
" Bundle 'scrooloose/nerdtree'
" Bundle 'mhinz/vim-signify'
" Bundle 'xoria256.vim'
" Bundle 'tpope/vim-liquid'
" Bundle 'tobinvanpelt/vim-semicolon'
" Bundle 'vim-ruby/vim-ruby'
" Bundle 'tpope/vim-abolish'
" Bundle 'tpope/vim-rails'
" Bundle 'Jinja'
" Bundle 'majutsushi/tagbar'
" Bundle 'aaronj1335/underscore-templates.vim'
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

" Background is dark
set background=dark

" Syntax highlighting
syntax on

" Set color scheme
colorscheme base16-tomorrow

" Set tab/spaces options
set ai et sw=4 sts=4 ts=4

" Set folding options
set foldmethod=indent

set wildmenu

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Set backup directory for files being edited
set backupdir=~/.vim/backup

" Get permission to edit file
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" Remembers last position in file
" au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" Set path to Jekyll blog for Jekyll.vim
" let g:jekyll_path = "~/Dev/chenn.github.com/"

" Highlight Jekyll post YAML content correctly
" execute "autocmd BufNewFile,BufRead " . g:jekyll_path . "/* syn match jekyllYamlFrontmatter /\\%^---\\_.\\{-}---$/ contains=@Spell"

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
if executable('coffeetags')
  let g:tagbar_type_coffee = {
        \ 'ctagsbin' : 'coffeetags',
        \ 'ctagsargs' : '--include-vars',
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

augroup myvimrc
    au!
    au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC
augroup END

" Start CtrlP in last used mode
let g:ctrlp_cmd = 'CtrlPLastMode'
let g:ctrlp_custom_ignore = ''

" vim-airline options
let g:airline_detect_whitespace=0
let g:airline_theme='simple'
let g:airline_left_sep=''
let g:airline_right_sep=''

" Some key mappings
map <S-t> :Tab /=<CR>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=M+\ 1mn\ light:h14
    set antialias
endif
