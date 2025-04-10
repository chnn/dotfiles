return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = {
    "milanglacier/minuet-ai.nvim",
  },
  config = function()
    require("blink-cmp").setup({
      completion = {
        documentation = { auto_show = true },
        list = {
          selection = {
            auto_insert = false,
          },
        },
      },
      keymap = {
        preset = "enter",
        ["<A-l>"] = require("minuet").make_blink_map(),
      },
      signature = { enabled = true },
      sources = {
        default = {
          "snippets",
          "lsp",
          "buffer",
          "path",
        },
        min_keyword_length = function()
          if vim.tbl_contains({
            "text",
            "markdown",
          }, vim.bo.filetype) then
            return 1000
          else
            return 1
          end
        end,
        providers = {
          lsp = {
            async = true,
          },
          minuet = {
            name = "minuet",
            module = "minuet.blink",
          },
        },
      },
    })
  end,
}
