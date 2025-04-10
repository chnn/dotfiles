return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("minuet").setup({
      provider = "gemini",
      provider_options = {
        gemini = { model = "gemini-2.0-flash" },
      },
    })
  end,
}
