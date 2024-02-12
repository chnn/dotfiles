return {
  {
    "epwalsh/obsidian.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("obsidian").setup({
        disable_frontmatter = true,
        mappings = {},
        workspaces = {
          {
            name = "Notes",
            path = os.getenv("NOTES"),
          },
        },
      })
    end,
  },
}
