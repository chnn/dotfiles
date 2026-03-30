vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/milanglacier/minuet-ai.nvim",
})

require("minuet").setup({
  provider = "claude",
  provider_options = {
    claude = { model = "claude-haiku-4-5" },
  },
})
