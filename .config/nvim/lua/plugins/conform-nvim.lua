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
        sql_formatter = {
          command = "sql-formatter",
          args = {
            "-c",
            [[{"language": "postgresql", "tabWidth": 2, "keywordCase": "lower", "dataTypeCase": "lower", "functionCase": "lower"}]],
          },
        },
      },
      formatters_by_ft = {
        css = { "prettierd", "prettier", stop_after_first = true },
        go = { "gofmt", "goimports" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        less = { "prettierd", "prettier", stop_after_first = true },
        lua = { "stylua" },
        rust = { "rustfmt" },
        terraform = { "terraform_fmt" },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      },
    })

    vim.keymap.set("n", "<leader>=", function()
      require("conform").format({ async = true, quiet = true })
    end, { desc = "Format buffer" })
  end,
}
