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
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'reedes/vim-pencil'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'SirVer/ultisnips'
Plug 'rstacruz/vim-hyperstyle', { 'for': 'css' }
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'AndrewRadev/splitjoin.vim'

" FML
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'

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

" Copy to system clipboard
vnoremap <leader>c "+y

" NeoVim terminal settings
if has('nvim')
  nnoremap <silent> <leader>t :terminal<CR>
  tnoremap <Esc> <C-\><C-n>
  au TermOpen * setlocal nonumber
endif

" Edit vimrc keybindings
nnoremap <leader>ev :vsplit ~/.vimrc<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Search for visual selection with //
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

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
nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>l :Rg<CR>
inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files --hidden')
let g:fzf_preview_window = ''
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.6, 'border': 'sharp' } }

" function! g:FzfFilesSource()
"   let l:base = fnamemodify(expand('%'), ':h:.:S')
"   let l:proximity_sort_path = $HOME . '/.cargo/bin/proximity-sort'

"   if base == '.'
"     return 'rg --files --hidden'
"   else
"     return printf('rg --files --hidden | %s %s', l:proximity_sort_path, expand('%'))
"   endif
" endfunction
" noremap <silent> <C-p> :call fzf#vim#files('', { 'source': g:FzfFilesSource(), 'options': '--tiebreak=index'})<CR>
" noremap <silent> <leader>p :call fzf#vim#files('', { 'source': g:FzfFilesSource(), 'options': '--tiebreak=index'})<CR>

" TypeScript
autocmd FileType typescript :set makeprg=tsc\ -p\ ./tsconfig.json\ --noEmit
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx

" Flow
let g:javascript_plugin_flow = 1

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

" ripgrep
set grepprg=rg\ --vimgrep\ --hidden

" <leader>g to grep for visual selection or word under cursor
nnoremap <silent> <leader>g :silent grep "<C-R><C-W>"<CR>:copen<CR>
vnoremap <silent> <leader>g "sy :silent grep "<C-R>s"<CR>:copen<CR>

" Automatically open the quickfix window on grep
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" Stripe-specific settings
if filereadable(expand('~/.vim/stripe.vim'))
  source ~/.vim/stripe.vim
endif

" coc.nvim
set updatetime=300
set shortmess+=c
set signcolumn=yes

hi CocErrorSign ctermfg=1 ctermbg=10
hi CocWarningSign ctermfg=3 ctermbg=10
hi CocInfoSign ctermfg=12 ctermbg=10

nmap <silent> [r <Plug>(coc-diagnostic-prev)
nmap <silent> ]r <Plug>(coc-diagnostic-next)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> <leader>a <Plug>(coc-codeaction)
nnoremap <silent> gh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Use <Tab> to trigger coc.nvim completion
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<Tab>" : coc#refresh()
inoremap <expr><S-Tab> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <CR> to confirm coc.nvim completion
if exists('*complete_info')
  inoremap <expr> <CR> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif
