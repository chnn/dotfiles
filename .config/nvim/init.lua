--[[

  Basic editor settings
  =====================

--]]

-- Pane settings
vim.o.wrap = false
vim.o.number = true
vim.o.laststatus = 2
vim.o.ruler = true
vim.o.cursorline = true
vim.o.signcolumn = 'yes'
vim.o.showmode = false

-- Show whitespace
vim.o.list = true
vim.cmd [[hi NonText ctermfg=11]]

-- Folds
vim.o.foldmethod = 'indent'
vim.o.foldlevel = 10
vim.g.markdown_folding = 1

-- Backup and undo settings
-- vim.o.directory = '~/.vim-tmp'
-- vim.o.backupdir = '~/.vim-tmp'
-- vim.o.backupcopy = 'yes'
-- vim.o.undofile = true
-- vim.o.undodir = '~/.vim/undodir'
vim.o.hidden = true

-- Identation
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.expandtab = true

-- Search
vim.o.incsearch = true
vim.o.hlsearch = true

-- Colors
vim.o.background = 'dark'
vim.o.termguicolors = true -- Use nicer colors (may require Neovim and fancy terminal)
vim.cmd [[colorscheme base16-ia-dark]]

-- Use ripgrep for :grep
vim.o.grepprg = 'rg --vimgrep --hidden'

--[[

  Keybindings
  ===========

--]]

-- Use space as leader
vim.g.mapleader = ' '

-- Keep selected text selected when fixing indentation
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Quick window navigation
vim.keymap.set('n', '<C-J>', '<C-W><C-J>')
vim.keymap.set('n', '<C-K>', '<C-W><C-K>')
vim.keymap.set('n', '<C-L>', '<C-W><C-L>')
vim.keymap.set('n', '<C-H>', '<C-W><C-H>')
vim.keymap.set('n', '<C-_>', '<C-W><C-_>')

-- Edit vimrc keybindings
vim.keymap.set('n', '<leader>ev', ':vsplit $MYVIMRC<cr>')
vim.keymap.set('n', '<leader>sv', ':source $MYVIMRC<cr>')

-- Make the current fold the only fold showing ("z This")
vim.keymap.set('n', 'zT', 'zMzvzczO', { silent = true})

-- Copy to the system clipboard
vim.keymap.set('n', '<leader>c', '"+yy', { silent = true})
vim.keymap.set('v', '<leader>c', '"+y', { silent = true})

-- <leader>g to grep for visual selection or word under cursor
vim.keymap.set('n', '<leader>g', ':silent grep "<C-R><C-W>"<CR>:copen<CR>', {silent = true})
vim.keymap.set('v', '<leader>g', '"sy :silent grep "<C-R>s"<CR>:copen<CR>', {silent = true})

--[[

  Plugins
  =======

--]]

-- Clone packer if necessary
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  packer_bootstrap = vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Our lord and savior
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'
  use 'tpope/vim-surround'
  use 'tpope/vim-commentary'
  use 'tpope/vim-unimpaired'
  use 'tpope/vim-vinegar'
  use 'tpope/vim-sleuth'
  use 'tpope/vim-repeat'
  use 'tpope/vim-rsi'
  use 'tpope/vim-abolish'

  use 'neovim/nvim-lspconfig'
  use 'folke/trouble.nvim'
  use 'nvim-lualine/lualine.nvim'

  use {
    'jose-elias-alvarez/null-ls.nvim',
    requires = {
      {'nvim-lua/plenary.nvim'},
    }
  }

  use {
    'hrsh7th/nvim-cmp',
    requires = {
      {'hrsh7th/vim-vsnip'},
      {'hrsh7th/vim-vsnip-integ'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'hrsh7th/cmp-cmdline'},
      {'hrsh7th/cmp-vsnip'},
    }
  }

  use '/usr/local/opt/fzf'
  use 'junegunn/fzf.vim'
  use 'junegunn/goyo.vim'
  use 'reedes/vim-pencil'
  use 'godlygeek/tabular'
  use 'neoclide/jsonc.vim'
  use 'rizzatti/dash.vim'
  use 'junegunn/vim-peekaboo'
  use 'chriskempson/base16-vim'

  use 'kana/vim-textobj-user'
  use 'lucapette/vim-textobj-underscore'
  use 'RyanMcG/vim-textobj-dash'

  use {
    'pangloss/vim-javascript',
    ft = {'javascript', 'javascriptreact', 'javascript.jsx'}
  }

  use {
    'maxmellon/vim-jsx-pretty',
    ft = {'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx'}
  }

  use {
    'leafgarland/typescript-vim',
    ft = {'typescript', 'typescriptreact', 'typescript.tsx'}
  }

  -- Automatically sync after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)

--[[

  Completion settings
  ===================

--]]

local cmp = require'cmp'

vim.o.completeopt = 'menu,menuone'
vim.o.shortmess = vim.o.shortmess .. 'c'
vim.o.updatetime = 300

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    -- ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item()),
    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item()),
  },
  sources = cmp.config.sources(
    {{ name = 'nvim_lsp' }},
    {{ name = 'buffer' }},
    {{ name = 'path' }}
  )
})

cmp.setup.cmdline('/', {
  sources = {{ name = 'buffer' }}
})

cmp.setup.cmdline(':', {
  sources = cmp.config.sources(
    {{ name = 'path' }},
    {{ name = 'cmdline' }}
  )
})


--[[

  LSP and diagnostic settings
  ===========================

  View LSP logs with:

      :lua vim.cmd('e'..vim.lsp.get_log_path())

  Logs can be made more verbose by setting:

      vim.lsp.set_log_level("debug")

--]]

vim.diagnostic.config({
  virtual_text = false,
  signs = {severity = {min = vim.diagnostic.severity.WARN}},
  underline = false,
  update_in_insert = false,
  severity_sort = false,
})

vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gh', vim.lsp.buf.hover)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)
vim.keymap.set('n', '[r', function() vim.diagnostic.goto_prev({severity = {min = vim.diagnostic.severity.WARN}}) end)
vim.keymap.set('n', ']r', function() vim.diagnostic.goto_next({severity = {min = vim.diagnostic.severity.WARN}}) end)
vim.keymap.set('n', '<space>f', vim.lsp.buf.formatting)
vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action)

local nvim_lsp = require('lspconfig')
local null_ls = require("null-ls")

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

nvim_lsp.flow.setup{
  capabilities = capabilities,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx" },
  flags = { debounce_text_changes = 100, },
}

nvim_lsp.tsserver.setup{
  capabilities = capabilities,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
  flags = { debounce_text_changes = 100, },
}

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.formatting.prettier
  },
  on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
      vim.cmd([[
      augroup lspformatting
        autocmd! * <buffer>
        autocmd bufwritepre <buffer> lua vim.lsp.buf.formatting_seq_sync()
      augroup end
      ]])
    end
  end,
})

require("trouble").setup {
  icons = false,
  fold_open = "",
  fold_closed = "",
  indent_lines = false,
  use_diagnostic_signs = true
}

vim.keymap.set('n', '<leader>j', ':Trouble<cr>', {silent = true})

--[[

  Statusline settings
  ===================

--]]

require('lualine').setup({
  options = {
    icons_enabled = false,
    globalstatus = true,
    section_separators = { left = '', right = '' },
    component_separators = { left = '', right = '' }
  },
  sections = {
    lualine_b = {'branch', 'diff'},
    lualine_c = {{'filename', path = 1}},
    lualine_x = {'diagnostics'},
    lualine_y = {'filetype'}
  }
})

--[[

  Unconverted vimscript config
  ======================

--]]

vim.cmd([[
" Treat kebab-cases variables as one word
set iskeyword+=-

" Stripe-specific settings
if filereadable(expand('~/.config/nvim/stripe.vim'))
  source ~/.config/nvim/stripe.vim
endif

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

" Automatically open the quickfix window on grep
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" Open docs in Dash with K
nmap <silent> K <Plug>DashSearch

autocmd CompleteDone * pclose
]])
