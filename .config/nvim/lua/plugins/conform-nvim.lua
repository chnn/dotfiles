return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters = {
          stylua = {
            command = "stylua",
            args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
          },
        },
        formatters_by_ft = {
          javascript = { { "prettierd", "prettier" } },
          css = { { "prettierd", "prettier" } },
          javascript = { { "prettierd", "prettier" } },
          javascriptreact = { { "prettierd", "prettier" } },
          json = { { "prettierd", "prettier" } },
          typescript = { { "prettierd", "prettier" } },
          typescriptreact = { { "prettierd", "prettier" } },
          rust = { "rustfmt" },
          lua = { "stylua" },
        },
        format_on_save = {
          lsp_fallback = false,
          timeout_ms = 500,
        },
      })
    end,
  },
}
