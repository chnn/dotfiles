-- LSP-driven format + lint-fix on save, plus <leader>= on demand.
--
-- Put in project nvim.lua
--
--     require("format").setup({
--       format_clients = { "rust_analyzer", "oxfmt" }, -- textDocument/formatting
--       fix_clients = { "oxlint" }, -- source.fixAll code actions
--     })
--

local M = {}

local function apply_fix_all(bufnr, fix_clients)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })) do
    if vim.tbl_contains(fix_clients, client.name) then
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = { only = { "source.fixAll" }, diagnostics = {} }
      local res = client:request_sync("textDocument/codeAction", params, 2000, bufnr)
      for _, action in ipairs((res or {}).result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        end
        if type(action.command) == "table" then
          client:exec_cmd(action.command)
        end
      end
    end
  end
end

function M.setup(opts)
  local format_clients = opts.format_clients or {}
  local fix_clients = opts.fix_clients or {}

  local function format_buffer(bufnr)
    apply_fix_all(bufnr, fix_clients)
    local function is_allowed(c)
      return vim.tbl_contains(format_clients, c.name)
    end
    local matches = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
    if not vim.iter(matches):any(is_allowed) then
      return
    end
    vim.lsp.buf.format({
      async = false,
      bufnr = bufnr,
      filter = is_allowed,
    })
  end

  local group = vim.api.nvim_create_augroup("user_lsp_format", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = function(args)
      format_buffer(args.buf)
    end,
  })

  vim.keymap.set("n", "<leader>=", function()
    format_buffer(vim.api.nvim_get_current_buf())
  end, { desc = "Format buffer via allowlisted LSPs" })
end

return M
