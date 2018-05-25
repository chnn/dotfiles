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
Plug 'SirVer/ultisnips'
Plug 'w0rp/ale'
Plug 'honza/vim-snippets'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'ajh17/Spacegray.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'chriskempson/base16-vim'
Plug 'godlygeek/tabular'
Plug 'vitaly/vim-gitignore'
Plug 'mustache/vim-mustache-handlebars'
Plug 'ap/vim-css-color'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': 'javascript' }
Plug 'leafgarland/typescript-vim'
Plug 'othree/html5.vim', { 'for': 'html' }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'lervag/vimtex'
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'racer-rust/vim-racer', { 'for': 'rust' }
Plug 'raichoo/haskell-vim', { 'for': 'haskell' }
Plug 'tpope/vim-salve', { 'for': 'clojure' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': 'clojure' }
Plug 'guns/vim-sexp', { 'for': 'clojure' }
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
set wildmenu

set background=light
colorscheme base16-solarized-light

" Keybindings
nnoremap <leader>d :YcmCompleter GoToDefinition<CR>
nnoremap <leader>r :YcmCompleter GoToReferences<CR>
nnoremap <leader>k :YcmCompleter GetDoc<CR>
nnoremap <leader>w :SoftPencil<CR>:Goyo<CR>
nnoremap <leader>lw :VimtexCompile<CR>:SoftPencil<CR>
vnoremap <C-a> :Tab /&<CR> :Tab /\\\\<CR>
tnoremap <ESC> <C-\><C-n><C-w><C-p>
nnoremap <leader>t :terminal<CR>:set nonumber<CR>i
nnoremap <leader>p :vsplit term://pipenv run ipython -i %<CR>:set nonumber<CR>i
vmap <F7> :w !pbcopy<CR><CR> 
nmap <F8> <Plug>(ale_fix)

" Keep selected text selected when fixing indentation
vnoremap < <gv
vnoremap > >gv

:command PandocPDF :!pandoc -o %:r.pdf %

if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

function! Incr()
  let a = line('.') - line("'<")
  let c = virtcol("'<")
  if a > 0
    execute 'normal! '.c.'|'.a."\<C-a>"
  endif
  normal `<
endfunction

vnoremap <C-i> :call Incr()<CR>

let g:ctrlp_working_path_mode = 'c'

" Ale
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0
let g:ale_fix_on_save = 1
let g:ale_javascript_prettier_use_local_config = 1
let g:ale_fixers = {'typescript': ['tslint'], 'javascript': ['eslint', 'prettier'], 'go': ['goimports']}
let g:ale_linters = {'typescript': ['tslint'], 'javascript': ['eslint', 'prettier'], 'python': ['flake8'], 'go': ['gometalinter']}

" Rust
let g:rustfmt_autosave = 0
let g:racer_cmd = "~/.cargo/bin/racer"
let g:racer_experimental_completer = 1
let g:ale_rust_cargo_check_all_targets = 0

" vim-pandoc
let g:pandoc#modules#disabled = ["formatting", "folding"]
let g:pandoc#syntax#conceal#use = 0

" vim-jsx
let g:jsx_ext_required = 0

" YCM
let g:ycm_python_binary_path = 'python'
let g:ycm_min_num_of_chars_for_completion = 4
let g:ycm_max_num_candidates = 10 
let g:ycm_max_num_identifier_candidates = 10 
let g:ycm_key_list_select_completion = []
let g:ycm_key_list_previous_completion = []
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_global_ycm_extra_conf = "~/Dev/.ycm_extra_conf.py"

" UltiSnips
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" vim-pencil
let g:pencil#textwidth = 79
let g:pencil#conceallevel = 0

" CtrlP
set wildignore+=*/node_modules/**
set wildignore+=*/_site/**
set wildignore+=*/tmp/**
set wildignore+=*/dist/**
set wildignore+=*/build/**

" VimTex
let g:vimtex_latexmk_options = '-pdf -shell-escape'
let g:vimtex_compiler_latexmk = {                                                          
\ 'backend': 'nvim',
\ 'background' : 1,                                                                        
\ 'build_dir' : '',                                                                        
\ 'callback' : 1,                                                                          
\ 'continuous' : 1,                                                                        
\ 'executable' : 'latexmk',                                                                
\ 'options' : [                                                                            
\   '-pdf',                                                                                
\   '-verbose',                                                                            
\   '-file-line-error',                                                                    
\   '-synctex=1',                                                                          
\   '-interaction=nonstopmode',                                                            
\   '-shell-escape',
\ ],                                                                                       
\}  
let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_indent_enabled = 0
let g:vimtex_index_show_help = 0
let g:vimtex_toc_show_numbers = 0
let g:vimtex_quickfix_mode = 1
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_view_method="skim"
if !exists('g:ycm_semantic_triggers')                                                                                        
  let g:ycm_semantic_triggers = {}                                                                                           
endif                                                                                                                        
let g:ycm_semantic_triggers.tex = g:vimtex#re#youcompleteme 
