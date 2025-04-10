return {
  "tinted-theming/tinted-vim",
  config = function()
    vim.o.termguicolors = true
    vim.o.background = "dark"
    vim.cmd.colorscheme("base24-ayu")
    vim.api.nvim_set_hl(0, "FlashLabel", { link = "lualine_a_normal" })
  end,
}
