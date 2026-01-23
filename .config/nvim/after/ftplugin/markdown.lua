-- Better indentation for soft-wrapped bullets in markdown files
vim.cmd([[autocmd FileType markdown set briopt+=list:-1]])

-- Use `<leader>x` to complete the current markdown bullet
vim.keymap.set("n", "<leader>x", function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local unchecked_pattern = "^(%s*[%-%*] )%[ %](.*)$"
  local checked_pattern = "^(%s*[%-%*] )%[x%](.*)$"

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

-- Go to a link or URL with `gd`
vim.keymap.set("n", "gd", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Pattern to match markdown links: [label](target) or [label](<target>)
  -- We need to find if cursor is within a markdown link
  local link_target = nil

  -- Search for markdown links in the current line
  local search_start = 1
  while true do
    -- Find the next markdown link pattern
    local bracket_start, bracket_end, label, target = line:find("%[([^%]]*)%]%(<?([^>%)]+)>?%)", search_start)

    if not bracket_start then
      break
    end

    -- Check if cursor is within this link (from [ to ))
    if col >= bracket_start and col <= bracket_end then
      link_target = target
      break
    end

    search_start = bracket_end + 1
  end

  if link_target then
    -- Determine if it's a URL or a file path
    if link_target:match("^https?://") or link_target:match("^www%.") then
      -- It's a URL, open with system browser
      vim.ui.open(link_target)
    else
      -- It's a file path, resolve relative to current file's directory
      local current_file = vim.fn.expand("%:p:h")
      local full_path = current_file .. "/" .. link_target .. ".md"

      -- Normalize the path (resolve .. and .)
      full_path = vim.fn.fnamemodify(full_path, ":p")

      -- Check if file exists
      if vim.fn.filereadable(full_path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      else
        vim.notify("File not found: " .. full_path, vim.log.levels.WARN)
      end
    end
  else
    -- Fall back to default gx behavior for non-markdown links
    -- Try to find a URL under cursor
    local url_pattern = "https?://[%w%.%-_~:/?#%[%]@!$&'%(%)%*%+,;=%%]+"
    local url_start, url_end = line:find(url_pattern)

    while url_start do
      if col >= url_start and col <= url_end then
        local url = line:sub(url_start, url_end)
        vim.ui.open(url)
        return
      end
      url_start, url_end = line:find(url_pattern, url_end + 1)
    end

    -- If no URL found, use netrw's gx or vim.ui.open on word under cursor
    local word = vim.fn.expand("<cfile>")
    if word and word ~= "" then
      vim.ui.open(word)
    end
  end
end, { desc = "Open link under cursor", buffer = true })
