if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'SirVer/ultisnips'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': 'javascript' }
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
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
set laststatus=1
set ruler
set hlsearch
set wildmenu
set cursorline
set completeopt+=noinsert

set background=light
colorscheme base16-atelier-seaside

set list
hi NonText ctermfg=11

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

" Quick window navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-_> <C-W><C-_>

" Misc bindings
if system('uname') == "Linux\n"
  vnoremap <silent> <leader>c :w !xclip -sel clipboard<CR><CR>
else
  vnoremap <silent> <leader>c :w !pbcopy<CR><CR> 
endif

" NeoVim terminal settings
if has('nvim')
  nnoremap <silent> <leader>t :terminal<CR>
  tnoremap <Esc> <C-\><C-n>
  au TermOpen * setlocal nonumber
endif

" FZF
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>l :Rg<CR>
inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files --hidden')

" ALE
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1

nmap <leader>d <Plug>(ale_detail)
nmap ]r <Plug>(ale_next_wrap)
nmap [r <Plug>(ale_previous_wrap)
nmap gd <Plug>(ale_go_to_definition)
nmap gh <Plug>(ale_hover)

hi clear ALEWarning
hi clear ALEWarningSign
hi clear ALEError
hi clear ALEErrorSign
hi ALEWarning cterm=underline
hi link ALEWarningSign Error
hi ALEError cterm=underline
hi link ALEErrorSign Error

let g:ale_linters = {
\   'javascript': ['tsserver'],
\   'typescript': ['tsserver'],
\   'go': ['gopls'],
\   'rust': ['rls'],
\   'python': ['pyls']
\}

let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\   'html': [],
\   'css': ['prettier'],
\   'scss': [],
\   'go': ['gofmt'],
\   'rust': ['rustfmt'],
\   'python': ['black']
\}

" typescript
autocmd FileType typescript :set makeprg=tsc\ -p\ ./tsconfig.json\ --noEmit

" rust
autocmd Filetype rust setlocal signcolumn=yes

" go
autocmd Filetype go setlocal ts=4
hi clear goSpaceError

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>

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

" vimtex
if system('uname') == "Linux\n"
  let g:vimtex_view_method="zathura"
else
  let g:vimtex_view_method="skim"
endif
