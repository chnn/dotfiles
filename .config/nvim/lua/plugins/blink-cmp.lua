return {
  "saghen/blink.cmp",
  version = "1.*",
  config = function()
    require("blink-cmp").setup({
      fuzzy = { implementation = "rust" },
      completion = {
        documentation = { auto_show = true },
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
        trigger = { prefetch_on_insert = false },
      },
      keymap = {
        preset = "enter",
        ["<C-S-l>"] = require("minuet").make_blink_map(),
        ["<C-l>"] = {
          function(cmp)
            if vim.bo.filetype == "markdown" then
              cmp.show({ providers = { "buffer" } })
            else
              cmp.show({ providers = { "lsp" } })
            end
          end,
        },
      },
      signature = { enabled = true },
      sources = {
        min_keyword_length = 3,
        default = { "snippets", "path", "buffer" },
        per_filetype = { markdown = { "snippets", "path" } },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000,
            score_offset = 50,
          },
        },
      },
    })
  end,
}
