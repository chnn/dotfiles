local M = {}

function M.theme()
  local c = require("flexoki.palette").get()
  local theme = {}
  for mode, color in pairs({
    normal = "cyan",
    insert = "green",
    visual = "purple",
    replace = "red",
    command = "orange",
    terminal = "blue",
  }) do
    theme[mode] = {
      a = { fg = c.bg, bg = c[color], gui = "bold" },
      b = { fg = c[color], bg = c.bg2 },
      c = { fg = c.tx, bg = c.bg2 },
    }
  end
  theme.inactive = {
    a = { fg = c.muted, bg = c.bg2 },
    b = { fg = c.muted, bg = c.bg2 },
    c = { fg = c.muted, bg = c.bg2 },
  }
  return theme
end

return M
