return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      treesitter = { label = { after = false } },
    },
  },
  keys = {
    {
      "R",
      mode = { "o", "x" },
      function()
        require("flash").treesitter_search()
      end,
      desc = "Treesitter Search",
    },
  },
}
