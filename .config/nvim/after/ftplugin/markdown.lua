-- Better indentation for soft-wrapped bullets in markdown files
vim.cmd([[autocmd FileType markdown set briopt+=list:-1]])

-- Use `<leader>x` to complete the current markdown bullet
vim.keymap.set("n", "<leader>x", function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local unchecked_pattern = "^(%s*- )%[ %](.*)$"
  local checked_pattern = "^(%s*- )%[x%](.*)$"

  local new_line
  if line:match(unchecked_pattern) then
    new_line = line:gsub(unchecked_pattern, "%1[x]%2")
  elseif line:match(checked_pattern) then
    new_line = line:gsub(checked_pattern, "%1[ ]%2")
  else
    return
  end

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end, { desc = "Toggle markdown checkbox" })
