-- Panes
vim.o.wrap = false
vim.o.number = true
vim.o.laststatus = 2
vim.o.ruler = true
vim.o.cursorline = false
vim.o.signcolumn = "yes"
vim.o.showmode = false
vim.o.relativenumber = true
vim.opt.fillchars:append({ vert = " " })

-- Folds
vim.o.foldmethod = "indent"
vim.o.foldlevel = 10
vim.g.markdown_folding = 1

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
vim.o.termguicolors = true -- Use nicer colors (may require Neovim and fancy terminal)

-- Use space as leader
vim.g.mapleader = " "

-- Show whitespace
vim.o.list = true
vim.cmd([[hi NonText ctermfg=11]])

-- Use ripgrep for :grep
vim.o.grepprg = "rg --vimgrep --hidden --iglob '!.git'"

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

-- Treat kebab-cases variables as one word
vim.opt.iskeyword:append("-")

-- Work-specific settings
pcall(require, "work")

-- Keep selected text selected when fixing indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Quicker window navigation keybindings
vim.keymap.set("n", "s", "<C-W>")
vim.keymap.set("n", "sm", "<C-W><C-_>")
vim.keymap.set("n", "su", "<C-W>=")

-- Edit vimrc keybindings
vim.keymap.set("n", "<leader>ev", ":e $MYVIMRC<CR>", { silent = true })
vim.keymap.set("n", "<leader>sv", ":source $MYVIMRC<CR>", { silent = true })

-- Copy to the system clipboard
vim.keymap.set("n", "<leader>c", '"+yy', { silent = true })
vim.keymap.set("v", "<leader>c", '"+y', { silent = true })

-- Exist terminal mode with Esc
vim.cmd([[tnoremap <Esc> <C-\><C-n>:q!<CR>]])

-- Close all buffers but this one with :Rlw ("reload workspace")
vim.cmd([[command! Rlw %bd|e#]])

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

  "RRethy/nvim-base16",

  "junegunn/goyo.vim",
  "reedes/vim-pencil",

  "junegunn/fzf",
  "junegunn/fzf.vim",
  "numToStr/Comment.nvim",
  "nvim-lualine/lualine.nvim",

  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/vim-vsnip",
  "hrsh7th/vim-vsnip-integ",
  "hrsh7th/cmp-vsnip",

  "neovim/nvim-lspconfig",

  "nvim-lua/plenary.nvim",
  "jose-elias-alvarez/null-ls.nvim",

  "nvim-treesitter/nvim-treesitter",
  "nvim-treesitter/nvim-treesitter-context",
  "nvim-treesitter/nvim-treesitter-textobjects",
  "nvim-treesitter/playground",

  "preservim/vim-markdown",

  "windwp/nvim-autopairs",
})

vim.cmd("colorscheme base16-gruvbox-dark-hard")

-- lualine.nvim
require("lualine").setup({
  options = {
    icons_enabled = false,
    globalstatus = false,
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { { "diagnostics", sections = { "error", "warn" } } },
    lualine_y = { "filetype" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
})

-- vim-fugitive
vim.keymap.set("n", "<leader>n", ":vert Git ++curwin log --oneline -n 30<CR>")
vim.cmd([[
augroup FugitiveKeymappings
  autocmd!
  autocmd FileType fugitive silent! nunmap <buffer> s
  autocmd FileType netrw silent! nunmap <buffer> s
augroup end
]])

-- goyo.vim and vim-pencil
vim.keymap.set("n", "<leader>w", ":Goyo<CR>", { silent = true })
vim.cmd([[
  function! s:goyo_enter()
    lua require('lualine').hide()
    call pencil#init({'wrap': 'soft'})
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
vim.keymap.set("n", "<leader>f", ":Files<CR>", { silent = true })
vim.keymap.set("n", "<leader>b", ":Buffers<CR>", { silent = true })
vim.keymap.set("n", "<leader>l", ":Rg<CR>", { silent = true })
vim.g.fzf_preview_window = {}

-- Comment.nvim
require("Comment").setup()

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

local completeopt = "menu,menuone,noinsert,preview"

vim.o.completeopt = completeopt
vim.o.shortmess = vim.o.shortmess .. "c"
vim.o.updatetime = 300

local diagnostic_severity = { min = vim.diagnostic.severity.WARN }

vim.diagnostic.config({
  virtual_text = false,
  signs = { severity = diagnostic_severity },
  underline = { severity = diagnostic_severity },
  update_in_insert = false,
  severity_sort = true,
})

vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gh", vim.lsp.buf.hover)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action)

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

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

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
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item()),
    ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item()),

    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
      elseif vim.fn["vsnip#available"](1) == 1 then
        feedkey("<Plug>(vsnip-expand-or-jump)", "")
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
      end
    end, { "i", "s" }),
  },
})

local nvim_lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

nvim_lsp.tsserver.setup({
  capabilities = capabilities,
  filetypes = {
    "javascript",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  flags = { debounce_text_changes = 100 },
  init_options = {
    preferences = { importModuleSpecifierPreference = "non-relative" },
  },
})

nvim_lsp.gopls.setup({ capabilities = capabilities })
nvim_lsp.rust_analyzer.setup({ capabilities = capabilities })

local null_ls = require("null-ls")
local null_ls_helpers = require("null-ls/helpers")
local null_ls_utils = require("null-ls/utils")
local format_augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.eslint_d.with({
      diagnostics_format = "[#{c}] #{m}",

      -- Works better for projects with a single root package.json and
      -- multiple nested .eslintrc.js config files
      cwd = null_ls_helpers.cache.by_bufnr(function(params)
        return null_ls_utils.root_pattern("package.json")(params.bufname)
      end),
    }),

    null_ls.builtins.formatting.prettier.with({
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "yaml",
        "markdown",
        "css",
      },
    }),

    null_ls.builtins.formatting.stylua.with({
      extra_args = { "--indent-width", "2", "--indent-type", "Spaces" },
    }),

    null_ls.builtins.formatting.gofmt,
    null_ls.builtins.formatting.goimports,
    null_ls.builtins.formatting.rustfmt,
  },

  on_attach = function(client, bufnr)
    if not client.supports_method("textDocument/formatting") then
      return
    end

    vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({
          bufnr = bufnr,
          filter = function(client)
            return client.name ~= "rust_analyzer" and client.name ~= "tsserver"
          end,
        })
      end,
    })
  end,
})

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
  },

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = { enable = true },

  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      -- include_surrounding_whitespace = true,

      keymaps = {
        ["ac"] = "@class.outer",
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      },

      selection_modes = {
        ["@function.outer"] = "V",
        ["@class.outer"] = "V",
      },
    },
  },

  playground = { enable = true },
})

require("nvim-autopairs").setup({})
