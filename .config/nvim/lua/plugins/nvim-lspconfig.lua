return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    local nvim_lsp = require("lspconfig")
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    nvim_lsp.eslint.setup({
      capabilities = capabilities,
      single_file_support = false,
      settings = {
        rulesCustomizations = {
          -- Disable annoying autofixable rules
          { rule = "prettier/prettier", severity = "off" },
          { rule = "arca/import-ordering", severity = "off" },
          { rule = "arca/newline-after-import-section", severity = "off" },
          { rule = "@typescript-eslint/consistent-type-imports", severity = "off" },
          { rule = "quotes", severity = "off" },
          { rule = "import/no-duplicates", severity = "off" },
          { rule = "unused-imports/no-unused-imports", severity = "off" },
        },
      },
    })

    nvim_lsp.ts_ls.setup({
      capabilities = capabilities,
      flags = { debounce_text_changes = 500 },
      init_options = {
        preferences = {
          importModuleSpecifierPreference = "non-relative",
          autoImportSpecifierExcludeRegexes = { "^packages" },
        },
        tsserver = {
          maxTsServerMemory = 32768,
          watchOptions = {
            excludeDirectories = { "**/node_modules", "**/.yarn", "**/.sarif" },
            excludeFiles = { ".pnp.cjs" },
          },
        },
      },
      on_attach = function(client, bufnr)
        -- Use built-in gq formatexpr
        vim.o.formatexpr = ""
      end,
    })

    nvim_lsp.gopls.setup({
      capabilities = capabilities,
      cmd = { "gopls", "--remote=auto" },
      settings = {
        gopls = {
          directoryFilters = {
            "-bazel-bin",
            "-bazel-out",
            "-bazel-testlogs",
            "-bazel-mypkg",
          },
          completeUnimported = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    })
  end,
}
