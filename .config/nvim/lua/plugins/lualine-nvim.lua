return {
  {
    "nvim-lualine/lualine.nvim",
    config = true,
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = false,
          section_separators = { left = "", right = "" },
          component_separators = { left = "", right = "" },
          theme = "base16",
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 1 }, "diff" },
          lualine_x = { { "diagnostics", sections = { "error", "warn" } } },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 1 } },
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
      })

      vim.o.laststatus = 1
    end,
  },
}
