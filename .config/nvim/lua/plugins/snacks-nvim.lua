return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true },
    picker = {
      layout = "ivy_split",
      formatters = {
        file = { truncate = 80 },
      },
      win = {
        input = {
          keys = {
            ["<ESC>"] = { "close", mode = { "n", "i" } },
            ["<C-u>"] = { "<C-o>cc", mode = { "i" }, expr = true },
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>f",
      function()
        Snacks.picker.smart()
      end,
      desc = "Open file picker",
    },
    {
      "<leader>b",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Open buffer picker",
    },
    {
      "<leader>d",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Open diagnostics picker",
    },
    {
      "<leader>/",
      function()
        Snacks.picker()
      end,
      desc = "Open pickers picker",
    },
    {
      "<leader>,",
      function()
        Snacks.picker.files({
          dirs = { "~/.config/nvim" },
        })
      end,
      desc = "Edit config",
    },
  },
}
