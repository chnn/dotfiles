return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  keys = {
    {
      "<space>nt",
      function()
        vim.cmd("Obsidian today")
      end,
      desc = "Open today's note",
    },
    {
      "<space>nn",
      function()
        vim.cmd("Obsidian new")
      end,
      desc = "Create a new note",
    },
    {
      "<space>nb",
      function()
        vim.cmd("Obsidian backlinks")
      end,
      desc = "Open file picker for backlinks",
    },
    {
      "<space>ng",
      function()
        vim.cmd("Obsidian search")
      end,
      desc = "Open grep for notes",
    },
    {
      "<space>np",
      function()
        vim.cmd("Obsidian quick_switch")
      end,
      desc = "Open a note",
    },
  },
  opts = {
    workspaces = { { name = "Notes", path = "~/Documents/Notes" } },
    legacy_commands = false,
    frontmatter = { enabled = false },
    footer = { enabled = false },
    picker = { name = "snacks.pick" },
    ui = { enable = false, ignore_conceal_warn = true },
    daily_notes = { folder = "days" },
    completion = { nvim_cmp = false, blink = true },
    preferred_link_style = "markdown",

    note_id_func = function(title)
      if title ~= nil then
        return os.date("%Y-%m-%d") .. " " .. title:gsub("[^A-Za-z0-9- ]", ""):lower()
      else
        local suffix = ""

        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end

        return tostring(os.time()) .. "-" .. suffix
      end
    end,
  },
}
