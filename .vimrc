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
Bundle 'git://git.wincent.com/command-t.git'
Bundle 'csexton/jekyll.vim'
Bundle 'tpope/vim-commentary'
Bundle 'scrooloose/syntastic'
Bundle 'skammer/vim-css-color'
Bundle 'othree/html5.vim'
Bundle 'tpope/vim-haml'
Bundle 'groenewege/vim-less'
Bundle 'tpope/vim-markdown'
Bundle 'vim-ruby/vim-ruby'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-abolish'
Bundle 'tpope/vim-liquid'
Bundle 'YankRing.vim'
Bundle 'godlygeek/tabular'
Bundle 'henrik/vim-ruby-runner'
Bundle 'vim-ruby/vim-ruby'

" Re-enable file detection after vundle has been called
filetype plugin indent on

" Turn off annoying bell
set visualbell

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

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Set backup directory for files being edited
set backupdir=~/.vim/backup

" Get permission to edit file
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" This beauty remembers where you were the last time you edited the file, and returns to the same position
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" Set path to Jekyll blog for Jekyll.vim
let g:jekyll_path = "~/Dev/chenn.io"

" Highlight Jekyll post YAML content correctly
execute "autocmd BufNewFile,BufRead " . g:jekyll_path . "/* syn match jekyllYamlFrontmatter /\\%^---\\_.\\{-}---$/ contains=@Spell"

" For markdown documents
command! -nargs=* Wrap set wrap linebreak nolist

" Some key mappings
map <S-n> :NERDTreeToggle<CR>
map <C-t> :CommandT<CR>
map <S-t> :Tab /=<CR>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=M+\ 1m\ light:h14
    set antialias
    set spell
endif
