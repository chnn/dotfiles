vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
  formatters = {
    stylua = {
      command = "stylua",
      args = { "--indent-type", "Spaces", "--indent-width", "2", "-" },
    },
  },
  formatters_by_ft = {
    lua = { "stylua" },
    terraform = { "terraform_fmt" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_format = "never",
  },
})
