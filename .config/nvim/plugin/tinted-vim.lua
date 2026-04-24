vim.pack.add({ "https://github.com/tinted-theming/tinted-vim" })
vim.cmd.colorscheme("base16-default-dark")

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("DiffHighlights", {}),
  callback = function()
    -- Diff backgrounds (subtle tinted backgrounds from base16 palette)
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2a3a2a", underline = false })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a2a2a" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2a2a3a", underline = false })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#3a4a3a", underline = false })

    -- Foreground colors used by gitsigns, diagnostics, etc.
    vim.api.nvim_set_hl(0, "Added", { fg = "#a1b56c" })
    vim.api.nvim_set_hl(0, "Removed", { fg = "#ab4642" })
    vim.api.nvim_set_hl(0, "Changed", { fg = "#7cafc2" })
  end,
})
vim.api.nvim_exec_autocmds("ColorScheme", { group = "DiffHighlights" })
