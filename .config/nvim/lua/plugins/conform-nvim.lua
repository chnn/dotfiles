return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      format_on_save = {
        lsp_fallback = false,
        timeout_ms = 500,
      },
      formatters = {
        stylua = {
          command = "stylua",
          args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
        },
      },
      formatters_by_ft = {
        javascript = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        less = { "prettierd", "prettier", stop_after_first = true },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        rust = { "rustfmt" },
        lua = { "stylua" },
        sql = { "sql_formatter" },
      },
    })

    vim.keymap.set("n", "<leader>=", function()
      require("conform").format({ async = true, quiet = true })
    end, { desc = "Format buffer" })
  end,
}
