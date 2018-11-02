call plug#begin('~/.vim/plugged')

" Our lord and savior
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-sleuth'

Plug 'ctrlpvim/ctrlp.vim'
Plug 'w0rp/ale'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'chriskempson/base16-vim'
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
Plug 'fatih/vim-go', { 'for': 'go' }

call plug#end()

filetype plugin indent on
set nowrap
set number
set foldmethod=indent
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp
set autoindent
set backspace=indent,eol,start
set smarttab
set incsearch
set laststatus=2
set ruler
set hlsearch
set wildmenu

set background=dark
colorscheme base16-oceanicnext

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

" Quick window navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-_> <C-W><C-_>

" Misc bindings
vnoremap <silent> <F7> :w !pbcopy<CR><CR> 

" Increment a list of numbers with Ctrl-I
function! Incr()
  let a = line('.') - line("'<")
  let c = virtcol("'<")
  if a > 0
    execute 'normal! '.c.'|'.a."\<C-a>"
  endif
  normal `<
endfunction

vnoremap <C-i> :call Incr()<CR>

" NeoVim terminal settings
if has('nvim')
  nnoremap <silent> <leader>t :terminal<CR>
  tnoremap <Esc> <C-\><C-n>
  au TermOpen * setlocal nonumber
endif

" ALE
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1

nmap <leader>d <Plug>(ale_detail)
nmap ]r <Plug>(ale_next_wrap)
nmap [r <Plug>(ale_previous_wrap)
nmap gd <Plug>(ale_go_to_definition)
nmap gh <Plug>(ale_hover)

hi SpellBad ctermbg=NONE ctermfg=NONE cterm=underline
hi ALEWarning ctermbg=NONE ctermfg=NONE cterm=underline

let g:ale_linters = {
\   'typescript': ['tsserver'],
\   'javascript': ['eslint'],
\   'python': ['pyls'],
\   'go': ['golangserver', 'gometalinter'],
\   'rust': ['rls']
\}

let g:ale_fixers = {
\   'typescript': ['tslint'],
\   'javascript': ['eslint'],
\   'go': ['gofmt'],
\   'rust': ['rustfmt']
\}

" vim-go
let g:go_fmt_autosave = 0
autocmd Filetype go setlocal tabstop=2

" rust
autocmd Filetype rust setlocal signcolumn=yes

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

" UltiSnips
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim-snippets']
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" ripgrep
set grepprg=rg\ --vimgrep

nnoremap <silent> <leader>r :silent grep "<C-R><C-W>"<CR>:copen<CR>
vnoremap <silent> <leader>r "sy :silent grep "<C-R>s"<CR>:copen<CR>

" dash.vim
nnoremap <silent> K :Dash!<CR>
