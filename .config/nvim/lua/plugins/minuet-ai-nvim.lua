return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "claude",
      provider_options = {
        claude = { model = "claude-sonnet-4-5-20250929" },
      },
    })
  end,
}
