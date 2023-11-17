-- Window
vim.o.shortmess = "filnxtToOFcI"
vim.o.laststatus = 2
vim.o.statusline = "%f %h%m%r%w%=%{strlen(&ft)?&ft:'none'} %-(%l,%c%)"

-- Panes
vim.o.wrap = false
vim.o.number = true
vim.o.relativenumber = false
vim.o.ruler = true
vim.o.cursorline = false
vim.o.signcolumn = "yes"
vim.opt.fillchars:append({ vert = " ", eob = " " })

-- Folds
vim.o.foldmethod = "indent"
vim.o.foldlevel = 10

-- Backup and undo
vim.o.hidden = false
vim.o.backupcopy = "yes"
vim.o.undofile = true
vim.o.directory = vim.fn.stdpath("cache") .. "/swap"
vim.o.backupdir = vim.fn.stdpath("cache") .. "/backup"
vim.o.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Identation
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.expandtab = true

-- Search and replace
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.inccommand = "split"

-- Colors
vim.o.background = "dark"
vim.o.termguicolors = true
vim.cmd("colorscheme base16-default-dark")

-- Use space as leader
vim.g.mapleader = " "

-- Show whitespace
vim.o.list = true
vim.cmd([[hi NonText ctermfg=11]])

-- Use ripgrep for :grep
vim.o.grepprg = "rg --vimgrep --hidden --iglob '!.git'"
vim.keymap.set("n", "<leader>/", ":grep ")

-- <leader>g to grep for visual selection or word under cursor
vim.keymap.set("n", "<leader>g", ':silent grep"<C-R><C-W>"<CR>:copen<CR>', { silent = true })
vim.keymap.set("v", "<leader>g", '"sy:silent grep"<C-R>s"<CR>:copen<CR>', { silent = true })

-- Automatically open the quickfix window on :grep
vim.cmd([[
augroup AutoOpenQuickFix
  autocmd!
  autocmd QuickFixCmdPost [^l]* nested cwindow
  autocmd QuickFixCmdPost    l* nested lwindow
augroup end
]])

-- Recognize words in snake_case and kebab-case
vim.opt.iskeyword:remove("-")
vim.opt.iskeyword:remove("_")

-- Keep selected text selected when fixing indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Quicker window navigation keybindings
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")
vim.keymap.set("n", "<C-_>", "<C-W><C-_>")

-- ; to exit visual mode
vim.keymap.set("v", ";", "<Esc>")

-- Edit vimrc keybindings
vim.keymap.set("n", "<leader>ev", ":e $MYVIMRC<CR>", { silent = true })
vim.keymap.set("n", "<leader>sv", ":source $MYVIMRC<CR>", { silent = true })

-- Copy to the system clipboard
vim.keymap.set("n", "<leader>y", '"+yy', { silent = true })
vim.keymap.set("v", "<leader>y", '"+y', { silent = true })
vim.keymap.set("n", "<leader>p", '"+p', { silent = true })
vim.keymap.set("n", "<leader>P", '"+P', { silent = true })

-- Exit terminal mode with Esc
vim.cmd([[tnoremap <Esc> <C-\><C-n>:q!<CR>]])

-- -- Better indentation for soft-wrapped bullets in markdown files
-- vim.cmd([[autocmd FileType markdown set briopt+=list:-1]])

-- Close all buffers but this one with :Rlw ("reload workspace")
vim.cmd([[command! Rlw %bd|e#]])

-- Write file with today's date prepended with :Wt
vim.cmd([[command! -nargs=1 Wt exe 'w ' . strftime("%F") . ' ' . "<args>"]])

-- If paq is not installed:
--
--     git clone --depth=1 https://github.com/savq/paq-nvim.git ~/.local/share/nvim/site/pack/paqs/start/paq-nvim
--
require("paq")({
  "savq/paq-nvim",

  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  "tpope/vim-surround",
  "tpope/vim-unimpaired",
  "tpope/vim-vinegar",
  "tpope/vim-sleuth",
  "tpope/vim-repeat",
  "tpope/vim-rsi",
  "tpope/vim-abolish",

  "godlygeek/tabular",
  "neoclide/jsonc.vim",
  "junegunn/vim-peekaboo",
  "wellle/targets.vim",
  "tinted-theming/base16-vim",
  "junegunn/goyo.vim",
  "reedes/vim-pencil",
  "numToStr/Comment.nvim",
  "nvim-lua/plenary.nvim",
  "nvim-treesitter/nvim-treesitter",
  "windwp/nvim-autopairs",
  "preservim/vim-markdown",
  "epwalsh/obsidian.nvim",

  "junegunn/fzf",
  "junegunn/fzf.vim",
  "gfanto/fzf-lsp.nvim",

  "neovim/nvim-lspconfig",
  { "j-hui/fidget.nvim", branch = "legacy" },
  "elentok/format-on-save.nvim",

  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/vim-vsnip",
  "hrsh7th/vim-vsnip-integ",
  "hrsh7th/cmp-vsnip",
  "hrsh7th/nvim-cmp",
})

-- Misc. plugins
require("Comment").setup()
require("nvim-autopairs").setup({})
require("fidget").setup({ text = { spinner = "dots" } })

-- vim-markdown
vim.g.vim_markdown_new_list_item_indent = 2
vim.g.vim_markdown_math = 1
vim.g.vim_markdown_frontmatter = 1
vim.cmd([[autocmd FileType markdown set conceallevel=2]])

-- obsidian.nvim
require("obsidian").setup({
  workspaces = {
    {
      name = "Notes",
      path = "~/Documents/Notes",
    },
  },

  note_id_func = function(title)
    if title ~= nil then
      return os.date("%Y-%m-%d") .. " " .. title
    end

    return os.date("%Y-%m-%d")
  end,

  disable_frontmatter = true,
})

-- goyo.vim and vim-pencil
vim.keymap.set("n", "<leader>w", ":Goyo<CR>", { silent = true })
vim.cmd([[let g:pencil#conceallevel = 2]])
vim.cmd([[
  function! s:goyo_enter()
    call pencil#init({'wrap': 'soft'})
    " hi clear StatusLine " Fix ^^^ from showing at bottom of buffer
  endfunction

  function! s:goyo_leave()
    call pencil#init({'wrap': 'off'})
  endfunction

  augroup GoyoSettings
    autocmd!
    autocmd! User GoyoEnter nested call <SID>goyo_enter()
    autocmd! User GoyoLeave nested call <SID>goyo_leave()
  augroup end
]])

-- fzf.vim
vim.g.fzf_preview_window = {}
vim.g.fzf_layout = { window = { width = 0.9, height = 0.9, border = "sharp" } }
vim.keymap.set("n", "<leader>f", ":Files<CR>", { silent = true })
vim.keymap.set("n", "<leader>b", ":Buffers<CR>", { silent = true })
vim.keymap.set("n", "<leader>l", ":Rg<CR>", { silent = true })
vim.keymap.set("n", "<leader>s", require("fzf_lsp").document_symbol_call)
vim.keymap.set("n", "<leader>S", require("fzf_lsp").workspace_symbol_call)
vim.keymap.set("n", "<leader>d", function()
  require("fzf_lsp").diagnostic_call({ severity = vim.diagnostic.severity.ERROR })
end)
vim.keymap.set("n", "<leader>D", function()
  require("fzf_lsp").diagnostic_call({ severity = vim.diagnostic.severity.ERROR, bufnr = nil })
end)

-- nvim-treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "python",
    "tsx",
    "ruby",
    "hcl",
    "markdown",
    "markdown_inline",
    "bash",
    "yaml",
    "query",
    "json",
  },

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<A-o>",
      node_incremental = "<A-o>",
      scope_incremental = "<A-O>",
      node_decremental = "<A-i>",
    },
  },
})

-- LSP and diagnostics settings
-- ----------------------------
--
-- To debug, set:
--
--     vim.lsp.set_log_level("debug")
--
-- View logs with:
--
--     :lua vim.cmd('e' .. vim.lsp.get_log_path())
--

local completeopt = "menu,menuone,noinsert,noselect,preview"

vim.o.completeopt = completeopt
vim.o.updatetime = 300

local diagnostic_severity = { min = vim.diagnostic.severity.WARN }

vim.diagnostic.config({
  virtual_text = false,
  signs = { severity = diagnostic_severity },
  underline = { severity = diagnostic_severity },
  update_in_insert = false,
  severity_sort = true,
})

vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gr", vim.lsp.buf.references)

vim.keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev({ severity = diagnostic_severity })
end)

vim.keymap.set("n", "]D", function()
  vim.diagnostic.goto_prev({ severity = diagnostic_severity })
end)

vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next({ severity = diagnostic_severity })
end)

vim.keymap.set("n", "[D", function()
  vim.diagnostic.goto_next({ severity = diagnostic_severity })
end)

vim.keymap.set("n", "<leader>j", function()
  vim.diagnostic.setqflist({ open = true, severity = diagnostic_severity })
end)

-- Open the full message for the first diagnostic under the cursor in a buffer
-- (useful for very long TypeScript errors)
vim.keymap.set("n", "ge", function()
  local lnum = vim.api.nvim_eval("line('.') - 1")
  local d = vim.diagnostic.get(0, { lnum = lnum, severity_sort = true })[1]

  if d == nil then
    return
  end

  -- Using a tmpfile because I can't figure out how to escape | and " when
  -- pasting a register using :put
  local tmpfile_path = vim.fn.stdpath("cache") .. "/diagnostic"
  local f = io.open(tmpfile_path, "w")
  f:write(d.message)
  f:close()
  vim.api.nvim_command("pedit " .. tmpfile_path)
end)

local cmp = require("cmp")

cmp.setup({
  completion = { completeopt = completeopt },

  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "vsnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),

  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },

  mapping = {
    ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item()),
    ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item()),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.abort(),
  },
})

local nvim_lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

nvim_lsp.jsonls.setup({ capabilities = capabilities })
nvim_lsp.rust_analyzer.setup({ capabilities = capabilities })

nvim_lsp.tsserver.setup({
  capabilities = capabilities,
  flags = { debounce_text_changes = 100 },
  init_options = {
    preferences = { importModuleSpecifierPreference = "non-relative" },
    maxTsServerMemory = 12288,
  },
  on_attach = function(client, bufnr)
    vim.o.formatexpr = "" -- Use built-in gq formatexpr
  end,
})

nvim_lsp.eslint.setup({
  capabilities = capabilities,
  settings = {
    rulesCustomizations = {
      { rule = "prettier/prettier", severity = "off" },
    },
  },
})

local format_on_save = require("format-on-save")
local formatters = require("format-on-save.formatters")

format_on_save.setup({
  formatter_by_ft = {
    css = formatters.prettierd,
    javascript = formatters.prettierd,
    json = formatters.prettierd,
    typescript = formatters.prettierd,
    typescriptreact = formatters.prettierd,
    rust = formatters.lsp,
    lua = formatters.shell({ cmd = { "stylua", "--indent-type", "Spaces", "--indent-width", "2", "-" } }),
  },
})
