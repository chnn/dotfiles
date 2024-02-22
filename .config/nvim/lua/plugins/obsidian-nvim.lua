return {
  "epwalsh/obsidian.nvim",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("obsidian").setup({
      disable_frontmatter = true,

      workspaces = {
        {
          name = "Notes",
          path = os.getenv("NOTES"),
        },
      },

      mappings = {
        ["gd"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
      },

      preferred_link_style = "markdown",

      note_id_func = function(title)
        if title ~= nil then
          return title
        else
          return os.date("%Y-%m-%d")
        end
      end,
    })

    -- Various highlight tweaks
    vim.api.nvim_set_hl(0, "@markup.italic.markdown_inline", { italic = true })
  end,
}
