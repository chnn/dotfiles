return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  config = function()
    require("nvim-treesitter.configs").setup({
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<A-o>",
          node_incremental = "<A-o>",
          node_decremental = "<A-i>",
        },
      },
    })
  end,
}
