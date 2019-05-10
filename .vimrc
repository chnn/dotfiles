if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Our lord and savior
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-sleuth'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'w0rp/ale'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'danielwe/base16-vim'
Plug 'godlygeek/tabular'
Plug 'vitaly/vim-gitignore'
Plug 'rizzatti/dash.vim'
Plug 'SirVer/ultisnips'
Plug 'joukevandermaas/vim-ember-hbs', { 'for': 'html.handlebars' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': 'javascript' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
Plug 'Vimjas/vim-python-pep8-indent', { 'for': 'python' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'fatih/vim-go', { 'for': 'go', 'do': ':GoUpdateBinaries' }
Plug 'elixir-editors/vim-elixir', { 'for': 'elixir' }
Plug 'lervag/vimtex', { 'for': 'tex' }

call plug#end()

filetype plugin indent on
set nowrap
set number
set foldmethod=indent
set foldlevel=10
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp
set backupcopy=yes
set autoindent
set backspace=indent,eol,start
set smarttab
set incsearch
set laststatus=2
set ruler
set hlsearch
set wildmenu

set background=dark
colorscheme base16-tomorrow-night

" Space as leader
let mapleader = "\<Space>" 

" Pretty status line
set statusline=
set statusline+=%f\ 
set statusline+=%h%m%r%w
set statusline+=%=
set statusline+=%{strlen(&ft)?&ft:'none'}\ 
set statusline+=%-(%l,%c%) 

" Keep selected text selected when fixing indentation
vnoremap < <gv
vnoremap > >gv

" Misc bindings
vnoremap <silent> <F7> :w !pbcopy<CR><CR> 
vnoremap <silent> <leader>c :w !xclip -sel clipboard<CR><CR>

" NeoVim terminal settings
if has('nvim')
  nnoremap <silent> <leader>t :terminal<CR>
  tnoremap <Esc> <C-\><C-n>
  au TermOpen * setlocal nonumber
endif

" FZF
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>l :Rg<CR>
nnoremap <silent> <expr> <leader>f i fzf#vim#complete#path('rg --files --hidden')
inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files --hidden')

" ALE
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
let g:ale_lint_delay = 100

nmap <leader>d <Plug>(ale_detail)
nmap ]r <Plug>(ale_next_wrap)
nmap [r <Plug>(ale_previous_wrap)
nmap gd <Plug>(ale_go_to_definition)
nmap gh <Plug>(ale_hover)

hi SpellBad ctermbg=NONE ctermfg=NONE cterm=underline
hi ALEWarning ctermbg=NONE ctermfg=NONE cterm=underline

let g:ale_linters = {
\   'javascript': [],
\   'typescript': ['tsserver'],
\   'python': ['pyls'],
\   'go': ['govet'],
\   'rust': ['rls'],
\   'elixir': ['elixir-ls']
\}

let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\   'html': [],
\   'css': [],
\   'scss': [],
\   'go': ['gofmt'],
\   'elixir': ['mix_format'],
\   'rust': ['rustfmt']
\}

" vim-go
let g:go_fmt_autosave = 0
autocmd Filetype go setlocal tabstop=2

" rust
autocmd Filetype rust setlocal signcolumn=yes
let g:ale_rust_rls_toolchain = 'stable'

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>

" ctrlp.vim
let g:ctrlp_working_path_mode = 'a'
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/node_modules/**
set wildignore+=*/vendor/**
set wildignore+=*/_site/**
set wildignore+=*/target/**
set wildignore+=*/_build/**

" UltiSnips
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim-snippets']
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" ripgrep
set grepprg=rg\ --vimgrep

nnoremap <silent> <leader>g :silent grep "<C-R><C-W>"<CR>:copen<CR>
vnoremap <silent> <leader>g "sy :silent grep "<C-R>s"<CR>:copen<CR>

autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" dash.vim
nnoremap <silent> <leader>k :Dash!<CR>

" vimtex
let g:vimtex_view_method="skim"

" elixir
let g:ale_elixir_elixir_ls_release = $HOME.'/.local/bin/elixir-ls'
