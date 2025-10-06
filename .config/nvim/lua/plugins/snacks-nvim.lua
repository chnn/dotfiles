return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true },
    picker = {
      layout = { preset = "ivy", preview = false },
      formatters = {
        file = { truncate = 80 },
      },
      icons = {
        files = { enabled = false },
      },
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<C-u>"] = { "<C-o>cc", mode = { "i" }, expr = true },
          },
        },
      },
    },
  },
  keys = {
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Go to definition",
    },
    {
      "gi",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Go to implementation",
    },
    {
      "gy",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Go to type definition",
    },
    {
      "gs",
      function()
        Snacks.picker.lsp_symbols({
          filter = {
            default = true,
          },
        })
      end,
      desc = "Go to type definition",
    },
    {
      "<D-p>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Open smart file picker",
    },
    {
      "<space>b",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Open buffer picker",
    },
    {
      "<space>F",
      function()
        Snacks.picker.files()
      end,
      desc = "Open file picker",
    },
    {
      "<space>/",
      function()
        Snacks.picker()
      end,
      desc = "Open pickers picker",
    },
    {
      "<space>,",
      function()
        Snacks.picker.files({
          dirs = { "~/.config/nvim" },
        })
      end,
      desc = "Edit config",
    },
    {
      "<space>r",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume last picker",
    },
  },
}
