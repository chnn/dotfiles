return {
  "saghen/blink.cmp",
  version = "1.*",
  config = function()
    require("blink-cmp").setup({
      fuzzy = { implementation = "rust" },
      completion = {
        documentation = {
          auto_show = true,
        },
        list = {
          selection = {
            auto_insert = false,
          },
        },
      },
      keymap = {
        preset = "enter",
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
            return 3
          end
        end,
        providers = {
          lsp = {
            async = true,
          },
        },
      },
    })
  end,
}
