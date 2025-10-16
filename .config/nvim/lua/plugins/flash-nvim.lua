return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      treesitter = { label = { after = false } },
      search = { enabled = true },
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
    {
      "<A-o>",
      mode = { "n", "o", "x" },
      function()
        require("flash").treesitter({
          actions = {
            ["<A-o>"] = "next",
            ["<A-i>"] = "prev",
          },
        })
      end,
      desc = "Treesitter incremental selection",
    },
  },
}
