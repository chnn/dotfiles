return {
  "epwalsh/obsidian.nvim",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- log_level = vim.log.levels.WARN,
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

    completion = {
      preferred_link_style = "markdown",
    },

    note_id_func = function(title)
      if title ~= nil then
        return title
      else
        return os.date("%Y-%m-%d")
      end
    end,
  },
}
