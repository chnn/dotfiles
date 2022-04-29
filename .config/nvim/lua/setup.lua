local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  }, {
    { name = 'buffer' },
  }, {
    { name = 'path' },
  })
})

cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- View LSP logs with:
--
--     :lua vim.cmd('e'..vim.lsp.get_log_path())
--
-- vim.lsp.set_log_level("debug")

vim.diagnostic.config({
  virtual_text = false,
  signs = {severity = {min = vim.diagnostic.severity.WARN}},
  underline = false,
  update_in_insert = false,
  severity_sort = false,
})

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

local nvim_lsp = require('lspconfig')
local null_ls = require("null-ls")

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local opts = { noremap=true, silent=true }

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gh', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '[r', '<cmd>lua vim.lsp.diagnostic.goto_prev({severity = {min = vim.diagnostic.severity.WARN}})<CR>', opts)
  buf_set_keymap('n', ']r', '<cmd>lua vim.lsp.diagnostic.goto_next({severity = {min = vim.diagnostic.severity.WARN}})<CR>', opts)
  -- buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  -- buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  -- buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  -- buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  -- buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  -- buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  -- buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  -- buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
end

nvim_lsp.flow.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx" },
  flags = { debounce_text_changes = 100, },
}

nvim_lsp.tsserver.setup{
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
  flags = { debounce_text_changes = 100, },
}

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.formatting.prettier
  },
  on_attach = function(client)
    if client.resolved_capabilities.document_formatting then
      vim.cmd([[
      augroup lspformatting
        autocmd! * <buffer>
        autocmd bufwritepre <buffer> lua vim.lsp.buf.formatting_seq_sync()
      augroup end
      ]])
    end
  end,
})

require("trouble").setup {
  icons = false,
  fold_open = "",
  fold_closed = "",
  indent_lines = false,
  use_diagnostic_signs = true
}


-- local fn = vim.fn
-- local o = vim.o
-- local cmd = vim.cmd

-- local function highlight(group, fg, bg)
--     cmd("highlight " .. group .. " guifg=" .. fg .. " guibg=" .. bg)
-- end

-- highlight("StatusLeft", "red", "#32344a")
-- highlight("StatusMid", "green", "#32344a")
-- highlight("StatusRight", "blue", "#32344a")

-- local function get_column_number()
--     return fn.col(".")
-- end

-- function status_line()
--     local statusline = ""
--     statusline = statusline .. "%#StatusLeft#"
--     statusline = statusline .. "%f"
--     statusline = statusline .. "%="
--     statusline = statusline .. "%#StatusMid#"
--     statusline = statusline .. "%l,%c"
--     -- statusline = statusline .. get_column_number()
--     statusline = statusline .. "%="
--     statusline = statusline .. "%#StatusRight#"

--     return statusline
-- end

-- o.statusline = "%!luaeval('status_line()')"
