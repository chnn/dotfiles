return {
  "stevearc/conform.nvim",
  config = function()
    vim.keymap.set("n", "<leader>=", function()
      require("conform").format({ async = true, quiet = true })
    end, { desc = "Format buffer" })

    require("conform").setup({
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
        css = { "prettier" },
        go = { "gofmt", "goimports" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        sql = { "sql_formatter" },
        json = { "prettier" },
        less = { "prettier" },
        lua = { "stylua" },
        rust = { "rustfmt" },
        terraform = { "terraform_fmt" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    })

    -- Set up on a per-project basis with something like this in .nvim.lua:
    --
    --     require("conform").setup({
    --       format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
    --       formatters_by_ft = {
    --         less = { "prettierd" },
    --         typescript = { lsp_format = "fallback" },
    --         typescriptreact = { lsp_format = "fallback" },
    --       },
    --     })
  end,
}
