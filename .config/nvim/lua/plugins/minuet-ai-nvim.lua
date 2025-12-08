return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "claude",
      provider_options = {
        claude = { model = "claude-haiku-4-5" },
      },
    })
  end,
}
