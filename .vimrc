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
Plug 'justinmk/vim-sneak'
Plug 'w0rp/ale'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'vitaly/vim-gitignore'
Plug 'rizzatti/dash.vim'
Plug 'Valloric/YouCompleteMe'
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
set nonumber
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
inoremap <C-j> <Esc>
nnoremap <silent> gd :YcmCompleter GoToDefinition<CR>
nnoremap <silent> gr :YcmCompleter GoToReferences<CR>
nnoremap <silent> gk :YcmCompleter GetDoc<CR>
nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>
nnoremap <silent> <F2> :set number!<CR>
vnoremap <silent> <F7> :w !pbcopy<CR><CR> 
nnoremap <silent> <leader>r :Rg <C-R><C-W><CR>
vnoremap <silent> <leader>r "sy :Rg <C-R>s<CR>
nnoremap <silent> <leader>c :terminal cargo run -q<CR>
nnoremap <silent> <leader>t :terminal<CR>
tnoremap <Esc> <C-\><C-n>
au TermOpen * setlocal nonumber

" Keep selected text selected when fixing indentation
vnoremap < <gv
vnoremap > >gv

:command PandocPDF :!pandoc -o %:r.pdf %

" Status Line
set statusline=
set statusline+=%n\ 
set statusline+=%f\ 
set statusline+=%h%m%r%w
set statusline+=%=
set statusline+=%-(%l,%c%)\ 
set statusline+=[%{strlen(&ft)?&ft:'none'}]

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
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_rust_rls_toolchain = 'stable'
let g:ale_linters = {
\   'typescript': ['tsserver'],
\   'javascript': ['eslint'],
\   'python': ['pyls'],
\   'go': ['gometalinter'],
\   'rust': ['rls']
\}
let g:ale_fixers = {
\   'typescript': ['tslint'],
\   'javascript': ['eslint'],
\   'go': ['gofmt'],
\   'rust': ['rustfmt']
\}
nmap <F8> <Plug>(ale_fix)
nmap <leader>d <Plug>(ale_detail)
nmap <C-j> <Plug>(ale_next_wrap)
nmap <C-k> <Plug>(ale_previous_wrap)
nmap gh <Plug>(ale_hover)
hi SpellBad ctermbg=NONE ctermfg=NONE cterm=underline
hi ALEWarning ctermbg=NONE ctermfg=NONE cterm=underline

" YCM
let g:ycm_min_num_of_chars_for_completion = 2
let g:ycm_max_num_candidates = 10
let g:ycm_max_num_identifier_candidates = 5
let g:ycm_key_list_select_completion = []
let g:ycm_key_list_previous_completion = []
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_show_diagnostics_ui = 0

" vim-go
let g:go_fmt_autosave = 0
autocmd Filetype go setlocal tabstop=2

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

" CtrlP
let g:ctrlp_working_path_mode = 'a'
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/node_modules/**
set wildignore+=*/vendor/**
set wildignore+=*/_site/**

" UltiSnips
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim-snippets']
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
