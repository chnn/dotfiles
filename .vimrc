call plug#begin('~/.vim/plugged')

" Our lord and savior
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-vinegar'

Plug 'ctrlpvim/ctrlp.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'Valloric/YouCompleteMe'
Plug 'w0rp/ale'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'vitaly/vim-gitignore'
Plug 'joukevandermaas/vim-ember-hbs', { 'for': 'handlebars' }
Plug 'ap/vim-css-color', { 'for': 'css' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': 'javascript' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
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
set complete-=i
set smarttab
set incsearch
set laststatus=1
set ruler
set hlsearch
set wildmenu

set background=dark
colorscheme base16-oceanicnext

" Keybindings
nnoremap <silent> gd :YcmCompleter GoToDefinition<CR>
nnoremap <silent> gr :YcmCompleter GoToReferences<CR>
nnoremap <silent> gk :YcmCompleter GetDoc<CR>
nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>
tnoremap <Esc> <C-\><C-n>
nnoremap <silent> <leader>t :terminal<CR>
vnoremap <silent> <F7> :w !pbcopy<CR><CR> 
nnoremap <silent> <leader>r :Rg <C-R><C-W><CR>

" Keep selected text selected when fixing indentation
vnoremap < <gv
vnoremap > >gv

:command PandocPDF :!pandoc -o %:r.pdf %

function! Incr()
  let a = line('.') - line("'<")
  let c = virtcol("'<")
  if a > 0
    execute 'normal! '.c.'|'.a."\<C-a>"
  endif
  normal `<
endfunction
vnoremap <C-i> :call Incr()<CR>

" Ale
let g:ale_lint_on_text_changed = 'always'
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
let g:ale_linters = {
\   'typescript': ['tsserver'],
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\   'go': ['gometalinter']
\}
let g:ale_fixers = {
\   'typescript': ['tslint'],
\   'javascript': ['eslint'],
\   'go': ['goimports']
\}
nnoremap <silent> <F8> <Plug>(ale_fix)
nnoremap <silent> <leader>d <Plug>(ale_detail)
nnoremap <silent> <C-j> <Plug>(ale_next)
nnoremap <silent> <C-k> <Plug>(ale_previous)
hi SpellBad ctermbg=green ctermfg=white

" YCM
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_max_num_candidates = 10 
let g:ycm_max_num_identifier_candidates = 10 
let g:ycm_key_list_select_completion = []
let g:ycm_key_list_previous_completion = []
let g:ycm_autoclose_preview_window_after_completion = 1

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

" CtrlP
let g:ctrlp_working_path_mode = 'a'
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/node_modules/**
set wildignore+=*/vendor/**
