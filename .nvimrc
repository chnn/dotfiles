call plug#begin('~/.vim/plugged')

" Our lord and savior
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
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
Plug 'ap/vim-css-color'
Plug 'neomake/neomake'
Plug 'rking/ag.vim'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'raichoo/haskell-vim', { 'for': 'haskell' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'tpope/vim-salve', { 'for': 'clojure' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': 'clojure' }
Plug 'guns/vim-sexp', { 'for': 'clojure' }
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'kchmck/vim-coffee-script', { 'for': 'coffee' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'editorconfig/editorconfig-vim'
Plug 'reedes/vim-pencil'
Plug 'junegunn/goyo.vim'
Plug 'chriskempson/base16-vim'
Plug 'altercation/vim-colors-solarized'

call plug#end()

set nowrap
set tabstop=8 softtabstop=0 expandtab shiftwidth=2 smarttab

set background=light
colorscheme solarized
let g:airline_theme='solarized'

" ctrlp options
let g:ctrlp_working_path_mode = 0
set wildignore+=*/build/**
set wildignore+=*/tmp/**
set wildignore+=*/dist/**
set wildignore+=*/bower_components/**
set wildignore+=*/node_modules/**
set wildignore+=*/docs/**
set wildignore+=*/staticfiles/**
set wildignore+=*.pyc

" .swp and backup file locations
set directory=~/.vim-tmp
set backupdir=~/.vim-tmp

" vim-airline options
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_section_error=''

autocmd Filetype javascript setlocal ts=2
let g:javascript_ignore_javaScriptdoc = 1

" Syntastic options
let g:syntastic_javascript_checkers = ['eslint']

" Neomake options
autocmd! BufWritePost,BufEnter * Neomake
let g:neomake_verbose = 0
let g:neomake_javascript_enabled_makers = ['eslint']
let g:neomake_tex_enabled_makers = []
let g:neomake_markdown_enabled_makers = []

" VimTex options
let g:vimtex_latexmk_options = '-pdf -xelatex -shell-escape'
let g:vimtex_indent_enabled = 0
let g:vimtex_index_show_help = 0
let g:vimtex_toc_show_numbers = 0
let g:vimtex_quickfix_mode = 1
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
let g:vimtex_view_general_options = '-r @line @pdf @tex'
let g:vimtex_latexmk_callback_hooks = ['UpdateSkim']

function! UpdateSkim(status)
  if !a:status | return | endif

  let l:out = b:vimtex.out()
  let l:tex = expand('%:p')
  let l:cmd = [g:vimtex_view_general_viewer, '-r']
  if !empty(system('pgrep Skim'))
    call extend(l:cmd, ['-g'])
  endif
  if has('nvim')
    call jobstart(l:cmd + [line('.'), l:out, l:tex])
  elseif has('job')
    call job_start(l:cmd + [line('.'), l:out, l:tex])
  else
    call system(join(l:cmd + [line('.'), shellescape(l:out), shellescape(l:tex)], ' '))
  endif
endfunction

" Workaround to enable clientserver support (for the vimtex quickfix window).
" This requires the `neovim-remote` package from PyPi.
let g:vimtex_latexmk_progname = 'nvr'  

" LaTeX support for YCM
au FileType tex let g:ycm_min_num_of_chars_for_completion = 4

if !exists('g:ycm_semantic_triggers')
  let g:ycm_semantic_triggers = {}
endif

let g:ycm_semantic_triggers.tex = [
\ 're!\\[A-Za-z]*cite[A-Za-z]*(\[[^]]*\]){0,2}{[^}]*',
\ 're!\\[A-Za-z]*ref({[^}]*|range{([^,{}]*(}{)?))',
\ 're!\\includegraphics\*?(\[[^]]*\]){0,2}{[^}]*',
\ 're!\\(include(only)?|input){[^}]*'
\ ]

let g:ycm_rust_src_path = '/usr/local/rust/rust-1.9.0/src'

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

nnoremap <leader>t :terminal<CR>
nnoremap <leader>c :ClearAllCtrlPCaches<CR>
nnoremap <leader>n :noh<CR>
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>
nnoremap <leader>lw :VimtexCompile<CR>:SoftPencil<CR>:set laststatus=0<CR>

