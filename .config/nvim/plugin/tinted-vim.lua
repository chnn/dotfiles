vim.pack.add({ "https://github.com/tinted-theming/tinted-vim" })
vim.cmd.colorscheme(vim.o.background == "dark" and "base16-measured-dark" or "base16-measured-light")

-- Make diffs easier to read: subtle red for removed lines, subtle green for added lines.
-- Colors are derived from the active base16 palette and blended toward the
-- editor background so they tint without overpowering the text.
local function blend(fg_hex, bg_hex, alpha)
  local function parse(hex)
    hex = hex:gsub("^#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end
  local fr, fg, fb = parse(fg_hex)
  local br, bg, bb = parse(bg_hex)
  local r = math.floor(fr * alpha + br * (1 - alpha) + 0.5)
  local g = math.floor(fg * alpha + bg * (1 - alpha) + 0.5)
  local b = math.floor(fb * alpha + bb * (1 - alpha) + 0.5)
  return string.format("#%02x%02x%02x", r, g, b)
end

local function set_diff_highlights()
  local bg = vim.g.base16_gui00
  local red = vim.g.base16_gui08
  local green = vim.g.base16_gui0B
  local blue = vim.g.base16_gui0D
  if not (bg and red and green and blue) then
    return
  end

  local alpha = 0.08
  local removed_bg = blend("#" .. red, "#" .. bg, alpha)
  local added_bg = blend("#" .. green, "#" .. bg, alpha)
  local changed_bg = blend("#" .. blue, "#" .. bg, alpha)
  local text_bg = blend("#" .. blue, "#" .. bg, alpha * 2)

  vim.api.nvim_set_hl(0, "DiffAdd", { bg = added_bg })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = removed_bg })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = changed_bg })
  vim.api.nvim_set_hl(0, "DiffText", { bg = text_bg, bold = true })
end

set_diff_highlights()

vim.api.nvim_create_autocmd({ "ColorScheme", "OptionSet" }, {
  pattern = { "*", "background" },
  callback = set_diff_highlights,
})
