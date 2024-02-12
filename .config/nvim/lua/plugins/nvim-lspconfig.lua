return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local nvim_lsp = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      nvim_lsp.jsonls.setup({ capabilities = capabilities })
      nvim_lsp.rust_analyzer.setup({ capabilities = capabilities, single_file_support = false })

      nvim_lsp.eslint.setup({
        capabilities = capabilities,
        single_file_support = false,
        settings = {
          rulesCustomizations = {
            { rule = "prettier/prettier", severity = "off" },
            { rule = "arca/import-ordering", severity = "off" },
            { rule = "arca/newline-after-import-section", severity = "off" },
            { rule = "quotes", severity = "off" },
          },
        },
      })
    end,
  },
}
