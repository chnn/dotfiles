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
      },
      -- Default formatters; can be overridden on a per-project basis with
      -- something like this in .nvim.lua:
      --
      --     require("conform").setup({
      --       format_on_save = {
      --         timeout_ms = 2000,
      --         lsp_format = "fallback",
      --       },
      --       formatters_by_ft = {
      --         less = { "prettierd" },
      --         typescript = { lsp_format = "prefer" },
      --         typescriptreact = { lsp_format = "prefer" },
      --       },
      --     })
      --
      formatters_by_ft = {
        css = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        less = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        go = { "gofmt", "goimports" },
        lua = { "stylua" },
        rust = { "rustfmt" },
        terraform = { "terraform_fmt" },
      },
    })
  end,
}
