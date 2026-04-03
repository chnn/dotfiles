vim.pack.add({ "https://github.com/tpope/vim-fugitive" })

-- When a fugitive status window opens: resize to 15 lines and scroll past
-- the Head/Push/Pull/Help header so only the actual git status is visible.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    vim.cmd("resize 10")
    vim.wo.number = false
    vim.wo.relativenumber = false
    -- gg: top of buffer, 4j: down past the 4 header lines, zt: put that line at top
    vim.cmd("normal! gg4jzt")
  end,
})
