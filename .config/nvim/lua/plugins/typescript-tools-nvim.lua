return {

  "pmizio/typescript-tools.nvim",
  config = function()
    local api = require("typescript-tools.api")
    require("typescript-tools").setup({
      separate_diagnostic_server = false,
      tsserver_file_preferences = {
        importModuleSpecifier = "non-relative",
        importModuleSpecifierEnding = "minimal",
      },
      handlers = {
        ["textDocument/publishDiagnostics"] = api.filter_diagnostics({
          80006, -- "may be converted to an async function"
          6133, -- "is assigned to a value but never used" (dupe of ESLint)
        }),
      },
      on_attach = function(client, bufnr)
        -- Use built-in gq formatexpr which works better for comments
        vim.o.formatexpr = ""

        -- Disable highlighting from tsserver
        client.server_capabilities.semanticTokensProvider = function() end
      end,
    })
  end,
}
