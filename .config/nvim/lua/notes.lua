-- Write file in the $NOTES directory with today's date prepended with :Wn
vim.api.nvim_create_user_command("Wn", function(opts)
  local title = opts.args
  if title == "" then
    vim.notify("Usage: :Wn <title>", vim.log.levels.ERROR)
    return
  end

  local notes_dir = os.getenv("NOTES")
  if not notes_dir then
    vim.notify("$NOTES environment variable is not set", vim.log.levels.ERROR)
    return
  end

  local date = os.date("%Y-%m-%d")
  local filename = date .. "_" .. title .. ".md"
  local filepath = notes_dir .. "/" .. filename

  vim.cmd("write " .. vim.fn.fnameescape(filepath))
  vim.notify("Saved to " .. filepath, vim.log.levels.INFO)
end, {
  nargs = 1,
  desc = "Write buffer to $NOTES folder with date prefix",
})

-- Create a new note in the $NOTES directory
vim.keymap.set("n", "<leader>nn", function()
  local notes_dir = os.getenv("NOTES")
  if not notes_dir then
    vim.notify("$NOTES environment variable is not set", vim.log.levels.ERROR)
    return
  end

  vim.ui.input({ prompt = "title: " }, function(title)
    if not title or title == "" then
      return
    end

    local date = os.date("%Y-%m-%d")
    local filename = date .. "_" .. title .. ".md"
    local filepath = notes_dir .. "/" .. filename

    vim.cmd.edit(filepath)
  end)
end, { desc = "Create new note" })

-- Create a new note and link to it from the current buffer
vim.keymap.set("n", "<leader>nl", function()
  local notes_dir = os.getenv("NOTES")
  if not notes_dir then
    vim.notify("$NOTES environment variable is not set", vim.log.levels.ERROR)
    return
  end

  local source_win = vim.api.nvim_get_current_win()

  vim.ui.input({ prompt = "title: " }, function(title)
    if not title or title == "" or not vim.api.nvim_win_is_valid(source_win) then
      return
    end

    local date = os.date("%Y-%m-%d")
    local filename = date .. "_" .. title .. ".md"
    local filepath = notes_dir .. "/" .. filename
    local source_buf = vim.api.nvim_win_get_buf(source_win)
    local cursor = vim.api.nvim_win_get_cursor(source_win)
    local link = "[](./" .. filename .. ")"

    if not vim.bo[source_buf].modifiable then
      vim.notify("Current buffer is not modifiable", vim.log.levels.ERROR)
      return
    end

    vim.api.nvim_set_current_win(source_win)
    vim.cmd("split " .. vim.fn.fnameescape(filepath))
    vim.api.nvim_buf_set_text(source_buf, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2], { link })
    vim.api.nvim_win_set_cursor(source_win, { cursor[1], cursor[2] + 1 })
    vim.api.nvim_set_current_win(source_win)
    vim.cmd.startinsert()
  end)
end, { desc = "Create and link new note" })

-- Create a daily note
vim.keymap.set("n", "<leader>nt", function()
  local notes_dir = os.getenv("NOTES")
  if not notes_dir then
    vim.notify("$NOTES environment variable is not set", vim.log.levels.ERROR)
    return
  end

  local date = os.date("%Y-%m-%d")
  local filename = date .. ".md"
  local filepath = notes_dir .. "/days/" .. filename

  vim.cmd.edit(filepath)
end, { desc = "Create daily note" })

-- Grep notes
vim.keymap.set("n", "<leader>ng", function()
  Snacks.picker.grep({
    dirs = { os.getenv("NOTES") },
  })
end, { desc = "Open grep for notes" })

-- Open a note
vim.keymap.set("n", "<leader>np", function()
  Snacks.picker.files({
    dirs = { os.getenv("NOTES") },
  })
end, { desc = "Open a note" })
