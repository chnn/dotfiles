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
vim.o.conceallevel = 0
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

-- Use space as leader
vim.g.mapleader = " "

-- Show whitespace
vim.o.list = true

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
vim.keymap.set("n", "<leader>x", ":.s/\\[ \\]/[x]<CR>:noh<CR>", { silent = true })

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

-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal insertion" })

-- Close all buffers but this one with :Rlw ("reload workspace")
vim.cmd([[command! Rlw %bd|e#]])

-- Write file with today's date prepended with :Wt
vim.cmd([[command! -nargs=1 Wt exe 'w ' . strftime("%F") . ' ' . "<args>"]])

-- Replace `\n` with actual newlines and remove `\` escape chars from quotes
vim.api.nvim_create_user_command("DecodeSQL", function()
  vim.cmd([[%s/\\n/\r/g]])
  vim.cmd([[%s/\\"/"/g]])
end, {})

-- LSP keybindings

local diagnostic_severity = { min = vim.diagnostic.severity.WARN }

vim.diagnostic.config({
  signs = { severity = diagnostic_severity },
  underline = { severity = diagnostic_severity },
  update_in_insert = false,
  severity_sort = true,
  jump = { float = true, severity = diagnostic_severity },
})

vim.keymap.set("n", "<D-.>", vim.lsp.buf.code_action, { desc = "Show code actions" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

vim.keymap.set("n", "<leader>e", function()
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
end, { desc = "Open diagnostic message in new buffer" })

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
