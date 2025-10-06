-- Window
vim.o.shortmess = "filnxtToOFcI"
vim.o.showmode = false
vim.o.showcmd = false

-- Panes
vim.o.wrap = false
vim.o.number = true
vim.o.ruler = true
vim.o.cursorline = false
vim.o.signcolumn = "yes"
vim.o.mouse = ""
vim.o.conceallevel = 2
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

-- Search and replace
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.inccommand = "split"

-- Use space as leader
vim.g.mapleader = " "

-- Show whitespace
vim.o.list = true

-- Default indent settings
vim.o.expandtab = true
vim.o.tabstop = 4 -- Display width of tab char
vim.o.shiftwidth = 4 -- Number of spaces used for indentation not in insert mode (with >>, ==, etc.)
vim.o.softtabstop = 4 -- How many spaces are inserted when pressing <Tab> in insert mode

-- Load .nvim.lua files in cwd and all parents if on the trust list
--
-- To mark a file as trusted, open it and run `:trust`
vim.o.exrc = true

-- Do not timeout for combo key presses
vim.o.timeout = false
vim.o.ttimeout = true

-- Use ripgrep for :grep
vim.o.grepprg = "rg --vimgrep --hidden --iglob '!.git'"

-- <leader>g to grep for visual selection or word under cursor
vim.keymap.set(
  "v",
  "<leader>g",
  '"sy:silent grep"<C-R>s"<CR>:copen<CR>',
  { silent = true, desc = "Grep for selection" }
)

-- Automatically open the quickfix window on :grep
vim.cmd([[
augroup AutoOpenQuickFix
  autocmd!
  autocmd QuickFixCmdPost [^l]* nested cwindow
  autocmd QuickFixCmdPost    l* nested lwindow
augroup end
]])

-- Keymap for yanking to the system cliipboard
vim.keymap.set({ "n", "x" }, "<leader>y", '"*y', { desc = "Yank to system clipboard" })

-- Navigate soft-lines by default
vim.keymap.set("n", "j", "gj", { desc = "Move cursor down" })
vim.keymap.set("n", "k", "gk", { desc = "Move cursor up" })

-- Better indentation for soft-wrapped bullets in markdown files
vim.cmd([[autocmd FileType markdown set briopt+=list:-1]])

-- Use `<leader>x` to complete the current markdown bullet
vim.keymap.set("n", "<leader>x", function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local unchecked_pattern = "^(%s*- )%[ %](.*)$"
  local checked_pattern = "^(%s*- )%[x%](.*)$"

  local new_line
  if line:match(unchecked_pattern) then
    new_line = line:gsub(unchecked_pattern, "%1[x]%2")
  elseif line:match(checked_pattern) then
    new_line = line:gsub(checked_pattern, "%1[ ]%2")
  else
    return
  end

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end, { desc = "Toggle markdown checkbox" })

-- Keep selected text selected when fixing indentation
vim.keymap.set("v", "<", "<gv", { desc = "Decrease selection indent" })
vim.keymap.set("v", ">", ">gv", { desc = "Increase selection indent" })

vim.keymap.set({ "n", "x" }, "gs", "^", { desc = "Go to first non-whitespace character of line" })
vim.keymap.set("n", "<C-/>", ":nohlsearch<CR>", { noremap = true, silent = true })

-- Quicker window navigation keybindings
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", { desc = "Go to pane below" })
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", { desc = "Go to pane above" })
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", { desc = "Go to pane to right" })
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", { desc = "Go to pane to left" })
vim.keymap.set("n", "<C-->", "<C-W><C-_>", { desc = "Expand pane" })
vim.keymap.set("n", "<C-=>", "<C-W><C-=>", { desc = "Equalize panes" })
vim.keymap.set("n", "<C-q>", "<C-W><C-q>", { desc = "Close pane" })
vim.keymap.set("n", "<C-s>", "<C-W>s", { desc = "Split pane" })

-- Shortcut to copy filename of buffer under the cursor to system clipboard
vim.keymap.set(
  "n",
  "<C-k>p",
  ':let @+=fnamemodify(expand("%"), ":~:.")<CR>',
  { silent = true, desc = "Copy path of current buffer to clipboard" }
)

-- Toggle statusline visibility
vim.keymap.set("n", "yo<space>", function()
  if vim.o.laststatus == 1 then
    vim.o.laststatus = 2
  else
    vim.o.laststatus = 1
  end
end, { silent = true, desc = "Toggle statusline visibility" })

-- Close all buffers but this one with :Rlw ("reload workspace")
vim.cmd([[command! Rlw %bd|e#]])

-- Write file with today's date prepended with :Wt
vim.cmd([[command! -nargs=1 Wt exe 'w ' . strftime("%F") . ' ' . "<args>"]])

-- Replace `\n` with actual newlines and remove `\` escape chars from quotes
vim.api.nvim_create_user_command("DecodeJSONString", function()
  vim.cmd([[%s/\\n/\r/g]])
  vim.cmd([[%s/\\"/"/g]])
end, {})

vim.diagnostic.config({
  signs = { severity = vim.diagnostic.severity.ERROR },
  underline = { severity = vim.diagnostic.severity.ERROR },
  update_in_insert = false,
  severity_sort = true,
  jump = { float = true, severity = vim.diagnostic.severity.ERROR },
})

vim.keymap.set("n", "<D-.>", vim.lsp.buf.code_action, { desc = "Show code actions" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      -- Disable highlighting from LSP servers (prefer Treesitter)
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

local function open_diagnostic_in_buffer()
  -- Get diagnostics at current cursor position
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

  if #diagnostics == 0 then
    vim.notify("No diagnostics found at cursor position", vim.log.levels.INFO)
    return
  end

  local diagnostic = diagnostics[1]

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diagnostic.message, "\n"))
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
end

vim.api.nvim_create_user_command("DiagnosticOpen", open_diagnostic_in_buffer, {})
vim.keymap.set("n", "<leader>do", open_diagnostic_in_buffer, { desc = "Open diagnostic in buffer" })

local function open_diagnostic_float_and_focus()
  local float_win = vim.diagnostic.open_float()
  if float_win then
    vim.api.nvim_set_current_win(float_win)
  end
end

-- Map to a key
vim.keymap.set("n", "<leader>df", open_diagnostic_float_and_focus, { desc = "Open and focus diagnostic float" })

-- Bootstrap lazy.nvim and load plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
})
