call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-markdown'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'othree/html5.vim'
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'kien/ctrlp.vim'
Plug 'Jelera/vim-javascript-syntax'
Plug 'mustache/vim-mustache-handlebars'
Plug 'godlygeek/tabular'
Plug 'ap/vim-css-color'
Plug 'scrooloose/syntastic'
Plug 'rking/ag.vim'
Plug 'airblade/vim-gitgutter'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --tern-completer --gocode-completer --racer-completer' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'raichoo/haskell-vim', { 'for': 'haskell' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'marijnh/tern_for_vim', { 'for': 'javascript', 'do': 'npm install' }
Plug 'tpope/vim-salve', { 'for': 'clojure' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': 'clojure' }
Plug 'guns/vim-sexp', { 'for': 'clojure' }
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'chriskempson/base16-vim'
Plug 'altercation/vim-colors-solarized'

call plug#end()

set visualbell
set mouse=a
set number
set nowrap
set foldmethod=indent
set foldlevel=1
set wildmode=full
set tabstop=2

" Set color scheme
set background=light
colorscheme solarized
let g:airline_theme='solarized'

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" ctrlp options
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
let g:airline_left_sep=''
let g:airline_right_sep=''

autocmd Filetype javascript setlocal ts=2
let g:javascript_ignore_javaScriptdoc = 1

" Syntastic options
let g:syntastic_html_checkers = ['']

" VimTex options
let g:vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
let g:vimtex_view_general_options = '@line @pdf @tex'
let g:vimtex_latexmk_options = '-pdf -xelatex'
let g:vimtex_indent_enabled = 0
let g:vimtex_index_show_help = 0
let g:vimtex_toc_show_numbers = 0
let g:vimtex_quickfix_mode = 1
let g:vimtex_quickfix_open_on_warning = 0
" Workaround to enable clientserver support (for the vimtex quickfix window).
" This requires the `neovim-remote` package from PyPi.
let g:vimtex_latexmk_progname = 'nvr'  

" LaTeX support for YCM
au FileType tex let g:ycm_min_num_of_chars_for_completion = 6

if !exists('g:ycm_semantic_triggers')
  let g:ycm_semantic_triggers = {}
endif

let g:ycm_semantic_triggers.tex = [
\ 're!\\[A-Za-z]*cite[A-Za-z]*(\[[^]]*\]){0,2}{[^}]*',
\ 're!\\[A-Za-z]*ref({[^}]*|range{([^,{}]*(}{)?))',
\ 're!\\includegraphics\*?(\[[^]]*\]){0,2}{[^}]*',
\ 're!\\(include(only)?|input){[^}]*'
\ ]

" YouCompleteMe leader shortcuts
nnoremap <leader>jd :YcmCompleter GoTo<CR>
nnoremap <leader>jr :YcmCompleter GoToReferences<CR>
nnoremap <leader>jk :YcmCompleter GetDoc<CR>

" vim-pencil options
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

" For using neovim pip package in virtualenvs
let g:python_host_prog = '/usr/local/bin/python'

" vim-go options
au FileType go nmap <leader>gt <Plug>(go-test)

" Exit NeoVim terminal mode with esc key
tnoremap <Esc> <C-\><C-n>
