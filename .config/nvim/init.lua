-- Window
vim.o.shortmess = "filnxtToOFcI"
vim.o.showmode = false
vim.o.showcmd = false
vim.o.statusline = "%f %h%m%r%w%= %-(%l,%c%)"

-- Panes
vim.o.wrap = false
vim.o.number = true
vim.o.relativenumber = false
vim.o.ruler = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.mouse = ""
vim.opt.fillchars:append({ vert = " ", eob = " " })

-- Folds
vim.o.foldmethod = "indent"
vim.o.foldlevel = 10

-- Backup and undo
vim.o.hidden = true
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

-- Diagnostics
local diagnostic_severity = { min = vim.diagnostic.severity.WARN }
vim.diagnostic.config({
  virtual_text = false,
  signs = { severity = diagnostic_severity },
  underline = { severity = diagnostic_severity },
  update_in_insert = false,
  severity_sort = true,
  float = {
    format = function(d)
      return "(" .. d.source .. ") " .. d.message
    end,
  },
})
vim.keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev({ severity = diagnostic_severity })
end)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next({ severity = diagnostic_severity })
end)
vim.keymap.set("n", "<leader>j", function()
  vim.diagnostic.setqflist({ open = true, severity = diagnostic_severity })
end)

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

-- Alternative improved clipboard behavior: paste is remapped to always paste
-- from the system clipboard, and yanks (y) and cuts (x) are sent to the system
-- clipboard as well. The default delete (d) behavior is left untouched. Yank
-- or cut text if you want it in the clipboard, otherwise delete it.
vim.keymap.set("n", "y", '"*y')
vim.keymap.set("x", "y", '"*y')
vim.keymap.set("x", "x", '"*x')
vim.keymap.set("n", "p", '"*p')
vim.keymap.set("n", "P", '"*P')

-- <leader>n to copy filename of buffer under the cursor to system clipboard
vim.keymap.set("n", "<leader>n", ':let @+=fnamemodify(expand("%"), ":~:.")<CR>', { silent = true })

-- Clear highlights
vim.cmd([[nmap <silent> <C-_> :nohlsearch<CR>:match<CR>:diffupdate<CR>]])

-- Keep selected text selected when fixing indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Quicker window navigation keybindings
vim.keymap.set("n", "<C-J>", "<C-W><C-J>")
vim.keymap.set("n", "<C-K>", "<C-W><C-K>")
vim.keymap.set("n", "<C-L>", "<C-W><C-L>")
vim.keymap.set("n", "<C-H>", "<C-W><C-H>")
vim.keymap.set("n", "<C-_>", "<C-W><C-_>")
vim.keymap.set("n", "<C-=>", "<C-W><C-=>")
vim.keymap.set("n", "<C-q>", "<C-W><C-q>")
vim.keymap.set("n", "<C-s>", "<C-W>s")

-- Edit vimrc keybindings
vim.keymap.set("n", "<leader>ev", ":e $MYVIMRC<CR>", { silent = true })
vim.keymap.set("n", "<leader>sv", ":source $MYVIMRC<CR>", { silent = true })

-- Exit terminal mode with Esc
vim.cmd([[tnoremap <Esc> <C-\><C-n>:q!<CR>]])

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
  "tpope/vim-sleuth",
  "tpope/vim-repeat",
  "tpope/vim-rsi",
  "tpope/vim-abolish",
  "godlygeek/tabular",
  "neoclide/jsonc.vim",
  "junegunn/vim-peekaboo",
  "wellle/targets.vim",
  "RRethy/nvim-base16",
  "junegunn/goyo.vim",
  "reedes/vim-pencil",
  "numToStr/Comment.nvim",
  "nvim-lua/plenary.nvim",
  "nvim-treesitter/nvim-treesitter",
  "windwp/nvim-autopairs",
  "preservim/vim-markdown",
  "nvim-lualine/lualine.nvim",
  "AndrewRadev/tagalong.vim",
  "stevearc/oil.nvim",
  "stevearc/conform.nvim",
  "github/copilot.vim",
  "neovim/nvim-lspconfig",
  { "ibhagwan/fzf-lua", branch = "main" },
  { "j-hui/fidget.nvim", branch = "legacy" },
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/vim-vsnip",
  "hrsh7th/vim-vsnip-integ",
  "hrsh7th/cmp-vsnip",
  "hrsh7th/nvim-cmp",
  "pmizio/typescript-tools.nvim",
})

-- Misc. plugins
require("Comment").setup()
require("nvim-autopairs").setup({})
require("fidget").setup({ text = { spinner = "dots" } })
vim.cmd("colorscheme base16-tomorrow-night")

-- Markdown settings
vim.g.vim_markdown_new_list_item_indent = 2
vim.g.vim_markdown_math = 1
vim.g.vim_markdown_frontmatter = 1
vim.cmd([[autocmd FileType markdown set conceallevel=0]])

-- oil.nvim
require("oil").setup({
  default_file_explorer = false,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
})
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Statusline
require("lualine").setup({
  options = {
    icons_enabled = false,
    globalstatus = false,
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
    theme = "base16",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { { "diagnostics", sections = { "error", "warn" } } },
    lualine_y = { "filetype" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
})
vim.o.laststatus = 2

-- Zen mode
vim.keymap.set("n", "<leader>w", ":Goyo<CR>", { silent = true })
vim.cmd([[let g:pencil#conceallevel = 0]])
vim.cmd([[
  function! s:goyo_enter()
    call pencil#init({'wrap': 'soft'})
    lua require('lualine').hide()
    hi clear StatusLine " Fix ^^^ from showing at bottom of buffer
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

-- Fzf
vim.keymap.set("n", "<M-p>", ":FzfLua files<CR>", { silent = true })
vim.keymap.set("n", "<leader>f", ":FzfLua files<CR>", { silent = true })
vim.keymap.set("n", "<leader>b", ":FzfLua buffers<CR>", { silent = true })
vim.keymap.set("n", "<leader>l", ":FzfLua live_grep<CR>", { silent = true })
vim.keymap.set("n", "<leader>s", ":FzfLua lsp_document_symbols<CR>", { silent = true })
vim.keymap.set("n", "<leader>S", ":FzfLua lsp_workspace_symbols<CR>", { silent = true })
vim.keymap.set("n", "<leader>d", ":FzfLua diagnostics_document<CR>", { silent = true })
vim.keymap.set("n", "<leader>D", ":FzfLua diagnostics_workspace<CR>", { silent = true })
require("fzf-lua").setup({
  files = { no_header = true },
  buffers = { no_header = true },
  live_grep = { no_header = true },
  winopts = {
    preview = { layout = "vertical" },
  },
})

-- Format on save
require("conform").setup({
  formatters = {
    stylua = {
      command = "stylua",
      args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
    },
  },
  formatters_by_ft = {
    javascript = { { "prettierd", "prettier" } },
    css = { { "prettierd", "prettier" } },
    javascript = { { "prettierd", "prettier" } },
    javascriptreact = { { "prettierd", "prettier" } },
    json = { { "prettierd", "prettier" } },
    typescript = { { "prettierd", "prettier" } },
    typescriptreact = { { "prettierd", "prettier" } },
    rust = { "rustfmt" },
    lua = { "stylua" },
  },
  format_after_save = {
    lsp_fallback = false,
  },
})

-- Treesitter
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
    "hurl",
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

-- Completion
local completeopt = "menu,menuone,noinsert,noselect,preview"
vim.o.completeopt = completeopt
vim.o.updatetime = 300
local cmp = require("cmp")
cmp.setup({
  completion = { completeopt = completeopt },

  sources = cmp.config.sources({
    { name = "buffer" },
  }, {
    { name = "nvim_lsp" },
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
cmp.setup.filetype("markdown", { sources = {} })
cmp.setup.filetype("text", { sources = {} })

vim.keymap.set("i", "<M-\\>", "<CMD>Copilot panel<CR>", { silent = true })
vim.g.copilot_filetypes = { text = false, markdown = false }

--- LSP
vim.keymap.set("n", "gh", vim.lsp.buf.hover)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gt", vim.lsp.buf.type_definition)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "gn", vim.lsp.buf.rename)

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

local nvim_lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

nvim_lsp.jsonls.setup({ capabilities = capabilities })
nvim_lsp.rust_analyzer.setup({ capabilities = capabilities, single_file_support = false })

nvim_lsp.eslint.setup({
  capabilities = capabilities,
  single_file_support = false,
  settings = {
    rulesCustomizations = {
      { rule = "prettier/prettier", severity = "off" },
      { rule = "arca/import-ordering", severity = "off" },
      { rule = "arca/newline-after-import-section", severity = "off" },
      { rule = "quotes", severity = "off" },
    },
  },
})

local api = require("typescript-tools.api")
require("typescript-tools").setup({
  separate_diagnostic_server = false,
  tsserver_file_preferences = {
    importModuleSpecifier = "non-relative",
    importModuleSpecifierEnding = "minimal",
  },
  handlers = {
    ["textDocument/publishDiagnostics"] = api.filter_diagnostics({
      80006, -- "may be converted to an async function"
      6133, -- "is assigned to a value but never used" (dupe of ESLint)
    }),
  },
  on_attach = function(client, bufnr)
    -- Use built-in gq formatexpr which works better for comments
    vim.o.formatexpr = ""

    -- Disable highlighting from tsserver
    client.server_capabilities.semanticTokensProvider = nil
  end,
})
