" Install vim-plug if necessary
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
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-repeat'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'w0rp/ale'
Plug 'reedes/vim-pencil'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'SirVer/ultisnips'
Plug 'rstacruz/vim-hyperstyle', { 'for': 'css' }
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'

" FML
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
" Plug 'yuezk/vim-js'
" Plug 'HerringtonDarkholme/yats.vim'
" Plug 'maxmellon/vim-jsx-pretty'

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
set shiftwidth=2
set tabstop=2
set expandtab
set incsearch
set laststatus=2
set ruler
set hlsearch
set wildmenu
set cursorline
set completeopt+=noinsert
set hidden

" Colorscheme
set background=dark
colorscheme base16-ia-dark
hi VertSplit ctermbg=10 ctermfg=10

" Show whitespace
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

" Only makes sense on the weirdo ErgoDox layout
nnoremap <C-I> <C-W><C-_>

" Edit vimrc keybindings
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Keybindings to copy to system clipboard
nnoremap <silent> <leader>c "+yy
vnoremap <silent> <leader>c "+y

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
let g:fzf_preview_window = ''

" TypeScript
autocmd FileType typescript :set makeprg=tsc\ -p\ ./tsconfig.json\ --noEmit
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx

" Flow
let g:javascript_plugin_flow = 1

" Rust
autocmd Filetype rust setlocal signcolumn=yes

" Go
autocmd Filetype go setlocal ts=4
hi clear goSpaceError

" vim-peekaboo
let g:peekaboo_delay = 200
let g:peekaboo_window = "vert bo 40new"

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>

" Support comments in JSON
autocmd FileType json syntax match Comment +\/\/.\+$+

" UltiSnips
let g:UltiSnipsSnippetDirectories=[$HOME.'/.vim-snippets']
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" ripgrep
set grepprg=rg\ --vimgrep\ --hidden

nnoremap <silent> <leader>g :silent grep "<C-R><C-W>"<CR>:copen<CR>
vnoremap <silent> <leader>g "sy :silent grep "<C-R>s"<CR>:copen<CR>

autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" ALE
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
let g:ale_completion_tsserver_autoimport = 1

nmap <leader>d <Plug>(ale_detail)
nmap ]r <Plug>(ale_next_wrap)
nmap [r <Plug>(ale_previous_wrap)
nmap gd <Plug>(ale_go_to_definition)
nmap gh <Plug>(ale_hover)

hi clear ALEWarning
hi clear ALEWarningSign
hi clear ALEError
hi clear ALEErrorSign
hi ALEWarning cterm=none
hi ALEWarningSign ctermfg=3 ctermbg=10
hi ALEError cterm=underline
hi ALEErrorSign ctermfg=9 ctermbg=10
hi link ALEErrorSign Error

let g:ale_linters = {
\   'javascript': ['eslint'],
\   'typescript': ['tsserver', 'eslint'],
\   'go': ['gopls'],
\   'python': ['pyls']
\}

let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'typescript': ['prettier'],
\   'markdown': ['prettier'],
\   'html': ['prettier'],
\   'css': ['prettier'],
\   'scss': [],
\   'go': ['gofmt'],
\   'rust': ['rustfmt'],
\   'ruby': [],
\   'python': ['black']
\}

" Stripe-specific settings
if filereadable(expand('~/.vim/stripe.vim'))
  source ~/.vim/stripe.vim
endif
