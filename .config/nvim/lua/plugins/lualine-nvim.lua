return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "ferdinandrau/lavish.nvim",
  },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = false,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        theme = "base16",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {},
        lualine_c = { { "filename", path = 1 }, "diff" },
        lualine_x = { { "diagnostics", sections = { "error", "warn" } }, "location" },
        lualine_y = { "filetype" },
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

    vim.api.nvim_create_autocmd("FileType", {
      desc = "Show statusbar for code files",
      pattern = { "typescript", "typescriptreact", "css", "less", "html", "lua", "rs", "sql" },
      group = vim.api.nvim_create_augroup("laststatus2", { clear = true }),
      callback = function(opts)
        vim.o.laststatus = 2
        vim.o.cursorline = true
      end,
    })
  end,
}
