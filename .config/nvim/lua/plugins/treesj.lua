return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("treesj").setup({ use_default_key_maps = false })
    vim.keymap.set("n", "<leader>m", require("treesj").toggle)
  end,
}
