return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "claude",
      provider_options = {
        claude = { model = "claude-opus-4-20250514" },
        gemini = {
          -- model = "gemini-2.5-flash-preview-05-20",
          model = "gemini-2.5-pro-preview-05-06",
        },
      },
    })
  end,
}
