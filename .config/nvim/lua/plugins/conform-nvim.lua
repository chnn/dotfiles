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
        javascript = { { "prettierd", "prettier" } },
        css = { { "prettierd", "prettier" } },
        less = { { "prettierd", "prettier" } },
        javascript = { { "prettierd", "prettier" } },
        javascriptreact = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        typescriptreact = { { "prettierd", "prettier" } },
        rust = { "rustfmt" },
        lua = { "stylua" },
      },
    })

    vim.keymap.set("n", "<leader>=", function()
      require("conform").format({ async = true, quiet = true })
    end, { desc = "Format buffer" })
  end,
}
