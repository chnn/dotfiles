" filename: .vimrc
" author: Chris Henn
" last updated: 3-18-11

" Turn off filetype to avoid conflicts with pathogen
filetype off
" Activate pathogen, easy vim plugin management
call pathogen#runtime_append_all_bundles() 
call pathogen#helptags()
" Re-enable file detection after pathogen has been called
filetype plugin indent on

" Turn on line numbering
set number

" Syntax highlighting
syntax on

" Background is dark
set background=dark

" Set colorscheme
colorscheme molokai

" Turn on paste mode, formatting doesn't mess up when pasting in code
set pastetoggle=<f12>

" Toggle numbers on/off for easy copying using <F2>:
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>

" Set backup directory for files being edited
set backupdir=~/.vim/backup

" Get permission to edit file
"cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" This beauty remembers where you were the last time you edited the file, and returns to the same position.
au BufReadPost * if line("'\"") > 0|if line("'\"") <= line("$")|exe("norm '\"")|else|exe "norm $"|endif|endif

" Some key mappings
map <S-n> :NERDTreeToggle<CR>

" Turn off toolbar in GUI
if has("gui_running")
    set guioptions=egmt
    set guioptions-=r
    set guifont=ProggyClean:h11
    set noantialias
endif
