-- Window
vim.o.shortmess = "filnxtToOFcI"
vim.o.showmode = false
vim.o.showcmd = false

-- Panes
vim.o.wrap = false
vim.o.number = true
vim.o.relativenumber = false
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
end, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next({ severity = diagnostic_severity })
end, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "<leader>j", function()
  vim.diagnostic.setqflist({ open = true, severity = diagnostic_severity })
end, { desc = "Open diagnostics in quickfix list" })

-- Use space as leader
vim.g.mapleader = " "

-- Show whitespace
vim.o.list = true

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

-- Alternative improved clipboard behavior: Yank or cut text if you want it in
-- the clipboard, otherwise delete it. Paste is remapped to always paste from
-- the system clipboard, and yanks (y) and cuts (x) are sent to the system
-- clipboard as well. The default delete (d) behavior is left untouched.
vim.keymap.set({ "n", "x" }, "x", '"*x', { desc = "Cut to system clipboard" })
vim.keymap.set({ "n", "x" }, "y", '"*y', { desc = "Yank to system clipboard" })
vim.keymap.set({ "n", "x" }, "p", '"*p', { desc = "Paste after cursor from system clipboard" })
vim.keymap.set({ "n", "x" }, "P", '"*P', { desc = "Paste before cursor from system clipboard" })

-- Various Helix-like keybindings
vim.keymap.set("n", "gh", "0", { desc = "Go to start of line" })
vim.keymap.set("n", "gl", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "gs", "^", { desc = "Go to first non-whitespace character of line" })
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

-- <leader>n to copy filename of buffer under the cursor to system clipboard
vim.keymap.set(
  "n",
  "<leader>n",
  ':let @+=fnamemodify(expand("%"), ":~:.")<CR>',
  { silent = true, desc = "Copy path of current buffer to clipboard" }
)

-- Keep selected text selected when fixing indentation
vim.keymap.set("v", "<", "<gv", { desc = "Decrease selection indent" })
vim.keymap.set("v", ">", ">gv", { desc = "Increase selection indent" })

-- Quicker window navigation keybindings
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", { desc = "Go to pane below" })
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", { desc = "Go to pane above" })
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", { desc = "Go to pane to right" })
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", { desc = "Go to pane to left" })
vim.keymap.set("n", "<C-_>", "<C-W><C-_>", { desc = "Expand pane" })
vim.keymap.set("n", "<C-=>", "<C-W><C-=>", { desc = "Equalize panes" })
vim.keymap.set("n", "<C-q>", "<C-W><C-q>", { desc = "Close pane" })
vim.keymap.set("n", "<C-s>", "<C-W>s", { desc = "Split pane" })

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

-- Diagnostics keybindings
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Open references in quickfix list" })
vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename symbol" })

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
