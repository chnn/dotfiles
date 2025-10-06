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
            preselect = false,
            auto_insert = true,
          },
        },
        trigger = {
          prefetch_on_insert = false,

          show_on_blocked_trigger_characters = function(ctx)
            if vim.bo.filetype == "markdown" then
              return { " ", "\n", "\t", ".", "/", "(", "[" }
            end

            return { " ", "\n", "\t" }
          end,
        },
      },
      keymap = {
        preset = "enter",
        ["<A-]>"] = require("minuet").make_blink_map(),
      },
      signature = { enabled = true },
      sources = {
        default = {
          "snippets",
          "lsp",
          "buffer",
          "path",
        },

        per_filetype = {
          markdown = { "snippets", "lsp", "path" },
        },

        min_keyword_length = 3,

        providers = {
          lsp = { async = true },
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
