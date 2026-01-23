vim.diagnostic.config({
  virtual_text = {
    source = "if_many",
    severity = { min = vim.diagnostic.severity.ERROR },
  },
  signs = { severity = vim.diagnostic.severity.ERROR },
  underline = { severity = vim.diagnostic.severity.ERROR },
  update_in_insert = false,
  severity_sort = true,
  jump = { float = true, severity = vim.diagnostic.severity.ERROR },
})

vim.keymap.set("n", "<D-.>", vim.lsp.buf.code_action, { desc = "Show code actions" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      -- Disable highlighting from LSP servers (prefer Treesitter)
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- Open the current diagnostic in a new buffer
local function open_diagnostic_in_buffer()
  -- Get diagnostics at current cursor position
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

  if #diagnostics == 0 then
    vim.notify("No diagnostics found at cursor position", vim.log.levels.INFO)
    return
  end

  local diagnostic = diagnostics[1]

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diagnostic.message, "\n"))
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
end
vim.api.nvim_create_user_command("DiagnosticOpen", open_diagnostic_in_buffer, {})
vim.keymap.set("n", "<leader>do", open_diagnostic_in_buffer, { desc = "Open diagnostic in buffer" })

-- Focus the current diagnostic float
local function open_diagnostic_float_and_focus()
  vim.diagnostic.open_float()
  vim.diagnostic.open_float()
end
vim.keymap.set("n", "<leader>df", open_diagnostic_float_and_focus, { desc = "Open and focus diagnostic float" })
