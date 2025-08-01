return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "claude",
      provider_options = {
        claude = { model = "claude-sonnet-4-20250514" },
        gemini = { model = "gemini-2.5-flash" },
      },
      virtualtext = {
        auto_trigger_ft = {},
        keymap = {
          accept = "<A-CR>",
          prev = "<A-[>",
          next = "<A-l>",
          dismiss = "<A-e>",
          -- accept_line = "<A-a>",
          -- accept_n_lines = "<A-z>",
        },
      },
    })
  end,
}
