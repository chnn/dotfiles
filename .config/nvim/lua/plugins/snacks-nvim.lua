return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true },
    picker = {
      layout = { preset = "ivy_split", preview = false },
      formatters = {
        file = { truncate = 80 },
      },
      win = {
        input = {
          keys = {
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
      "<D-p>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Open smart file picker",
    },
    {
      "<D-.>",
      vim.lsp.buf.code_action,
      desc = "Show code actions",
    },
    {
      "<space>b",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Open buffer picker",
    },
    {
      "<space>r",
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "Show references",
    },
    {
      "<space><space>f",
      function()
        Snacks.picker.files()
      end,
      desc = "Open file picker",
    },
    {
      "<space><space>m",
      function()
        Snacks.picker.recent()
      end,
      desc = "Open recent files picker",
    },
    {
      "<space><space>d",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Open diagnostics picker",
    },
    {
      "<space><space>/",
      function()
        Snacks.picker()
      end,
      desc = "Open pickers picker",
    },
    {
      "<space><space>,",
      function()
        Snacks.picker.files({
          dirs = { "~/.config/nvim" },
        })
      end,
      desc = "Edit config",
    },
    {
      "<space><space>r",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume last picker",
    },
  },
}
