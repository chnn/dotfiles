set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

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
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-abolish'

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/plenary.nvim' " Required for null-ls and Telescope
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'folke/trouble.nvim'
Plug 'kyazdani42/nvim-web-devicons'
" Plug 'nvim-telescope/telescope.nvim'

Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/nvim-cmp'

Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/goyo.vim'
Plug 'reedes/vim-pencil'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'neoclide/jsonc.vim'
Plug 'rizzatti/dash.vim'
Plug 'junegunn/vim-peekaboo'

Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'

Plug 'kana/vim-textobj-user'
Plug 'lucapette/vim-textobj-underscore'
Plug 'RyanMcG/vim-textobj-dash'


call plug#end()

filetype plugin indent on
set nowrap
set number
set foldmethod=indent
set foldlevel=10
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp
set backupcopy=yes
set undofile
set undodir=~/.vim/undodir
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
set completeopt-=preview
set hidden

" Colorscheme
set background=dark
colorscheme base16-ia-dark
hi VertSplit ctermbg=10 ctermfg=10

" Use nicer colors (may require NeoVim and fancy terminal)
set termguicolors

" Show whitespace
set list
hi NonText ctermfg=11

" Space as leader
let mapleader = "\<Space>" 

" Allow folding markdown
let g:markdown_folding = 1

" Treat kebab-cases variables as one word
set iskeyword+=-

" Pretty status line
set statusline=
set statusline+=%f\ 
set statusline+=%h%m%r%w
set statusline+=%=
set statusline+=%{strlen(&ft)?&ft:'none'}\ 
set statusline+=%-(%l,%c%) 

" Stripe-specific settings
if filereadable(expand('~/.config/nvim/stripe.vim'))
  source ~/.config/nvim/stripe.vim
endif

lua require('setup')

" Keep selected text selected when fixing indentation
vnoremap < <gv
vnoremap > >gv

" Quick window navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-_> <C-W><C-_>

" Edit vimrc keybindings
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Search for visual selection with //
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" Make the fold that we're currently in the only fold showing ("z This")
nnoremap <silent> zT zMzvzczO

" Keybindings to copy to system clipboard
nnoremap <silent> <leader>c "+yy
vnoremap <silent> <leader>c "+y

" Keybinding to open :Trouble 
nnoremap <leader>j :Trouble<cr>

" NeoVim terminal settings
nnoremap <silent> <leader>t :terminal<CR>
tnoremap <Esc> <C-\><C-n>
au TermOpen * setlocal nonumber

" FZF
nnoremap <silent> <leader>p :Files<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>l :Rg<CR>
inoremap <expr> <c-x><c-f> fzf#vim#complete#path('rg --files --hidden')
let g:fzf_preview_window = ''
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.6, 'border': 'sharp' } }

" Use proximity-sort for FZF
function! g:FzfFilesSource()
  let l:base = fnamemodify(expand('%'), ':h:.:S')
  let l:proximity_sort_path = $HOME . '/.local/bin/proximity-sort'

  if base == '.'
    return "rg --files --hidden -g '!.git'"
  else
    return printf("rg --files --hidden -g '!.git' | %s %s", l:proximity_sort_path, expand('%'))
  endif
endfunction
noremap <silent> <leader>p :call fzf#vim#files('', { 'source': g:FzfFilesSource(), 'options': '--tiebreak=index'})<CR>

" TypeScript
autocmd FileType typescript :set makeprg=tsc\ -p\ ./tsconfig.json\ --noEmit
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
autocmd BufNewFile,BufRead tsconfig.json set filetype=jsonc

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0
nnoremap <silent> <leader>w :SoftPencil<CR>:Goyo<CR>

" Support comments in JSON
autocmd FileType json syntax match Comment +\/\/.\+$+

" Treat XHTML as HTML
au BufRead,BufNewFile *.html set filetype=html

" ripgrep
set grepprg=rg\ --vimgrep\ --hidden

" <leader>g to grep for visual selection or word under cursor
nnoremap <silent> <leader>g :silent grep "<C-R><C-W>"<CR>:copen<CR>
vnoremap <silent> <leader>g "sy :silent grep "<C-R>s"<CR>:copen<CR>

" Automatically open the quickfix window on grep
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" Open docs in Dash with K
nmap <silent> K <Plug>DashSearch

set updatetime=300
set shortmess+=c
set signcolumn=yes

" Navigate the autocomplete menu with Tab and S-Tab
" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" highlight LspDiagnosticsDefaultError ctermfg=9
" highlight LspDiagnosticsSignError ctermfg=9 ctermbg=10
" highlight LspDiagnosticsDefaultHint ctermfg=11
" highlight LspDiagnosticsSignHint ctermfg=11 ctermbg=10
" highlight LspDiagnosticsDefaultInfo ctermfg=12
" highlight LspDiagnosticsSignInfo ctermfg=12 ctermbg=10
" highlight LspDiagnosticsDefaultWarning ctermfg=3
" highlight LspDiagnosticsSignWarning ctermfg=3 ctermbg=10
autocmd CompleteDone * pclose

" coc.nvim

" hi CocErrorSign ctermfg=1 ctermbg=10
" hi CocWarningSign ctermfg=3 ctermbg=10
" hi CocInfoSign ctermfg=12 ctermbg=10
" hi CocHintSign ctermfg=11

" nmap <silent> [r <Plug>(coc-diagnostic-prev)
" nmap <silent> ]r <Plug>(coc-diagnostic-next)
" nmap <silent> gd <Plug>(coc-definition)
" nnoremap <silent> gh :call <SID>show_documentation()<CR>
" nmap <silent> gr <Plug>(coc-references)
" nmap <leader>rn <Plug>(coc-rename)
" " nmap <silent> gd <Plug>(coc-implementation)
" " nmap <silent> <leader>a <Plug>(coc-codeaction)

" function! s:show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   else
"     call CocAction('doHover')
"   endif
" endfunction


" " Enter confirms completion in pop up menu
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
"                                          \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" " Remap <C-f> and <C-b> for scroll float windows/popups
" nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
" nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
" inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
" inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
" vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
" vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-b>"

" " Map function and class text objects
" xmap if <Plug>(coc-funcobj-i)
" omap if <Plug>(coc-funcobj-i)
" xmap af <Plug>(coc-funcobj-a)
" omap af <Plug>(coc-funcobj-a)
" xmap ic <Plug>(coc-classobj-i)
" omap ic <Plug>(coc-classobj-i)
" xmap ac <Plug>(coc-classobj-a)
" omap ac <Plug>(coc-classobj-a)
