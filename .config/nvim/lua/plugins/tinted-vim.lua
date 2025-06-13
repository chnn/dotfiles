return {
  "tinted-theming/tinted-vim",
  config = function()
    vim.o.termguicolors = true
    vim.o.background = "light"
    vim.cmd.colorscheme("base16-one-light")
    vim.api.nvim_set_hl(0, "FlashLabel", { link = "lualine_a_normal" })
  end,
}
