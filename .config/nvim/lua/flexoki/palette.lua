-- Flexoki by Steph Ango: https://stephango.com/flexoki (MIT; see LICENSE).
-- Keep pigment colors on the published ramps, never alpha-blend accents.
local M = {}

M.base = {
  black = "#100F0F",
  paper = "#FFFCF0",
  [50] = "#F2F0E5",
  [100] = "#E6E4D9",
  [150] = "#DAD8CE",
  [200] = "#CECDC3",
  [300] = "#B7B5AC",
  [400] = "#9F9D96",
  [500] = "#878580",
  [600] = "#6F6E69",
  [700] = "#575653",
  [800] = "#403E3C",
  [850] = "#343331",
  [900] = "#282726",
  [950] = "#1C1B1A",
}

-- Only the stops used by the theme are needed here.
M.accents = {
  red = {
    [50] = "#FFE1D5",
    [100] = "#FFCABB",
    [200] = "#F89A8A",
    [300] = "#E8705F",
    [400] = "#D14D41",
    [600] = "#AF3029",
    [700] = "#942822",
    [800] = "#6C201C",
    [900] = "#3E1715",
    [950] = "#261312",
  },
  orange = {
    [50] = "#FFE7CE",
    [100] = "#FED3AF",
    [200] = "#F9AE77",
    [300] = "#EC8B49",
    [400] = "#DA702C",
    [600] = "#BC5215",
    [700] = "#9D4310",
    [800] = "#71320D",
    [900] = "#40200D",
    [950] = "#27180E",
  },
  yellow = {
    [50] = "#FAEEC6",
    [100] = "#F6E2A0",
    [200] = "#ECCB60",
    [300] = "#DFB431",
    [400] = "#D0A215",
    [600] = "#AD8301",
    [700] = "#8E6B01",
    [800] = "#664D01",
    [900] = "#3A2D04",
    [950] = "#241E08",
  },
  green = {
    [50] = "#EDEECF",
    [100] = "#DDE2B2",
    [200] = "#BEC97E",
    [300] = "#A0AF54",
    [400] = "#879A39",
    [600] = "#66800B",
    [700] = "#536907",
    [800] = "#3D4C07",
    [900] = "#252D09",
    [950] = "#1A1E0C",
  },
  cyan = {
    [50] = "#DDF1E4",
    [100] = "#BFE8D9",
    [200] = "#87D3C3",
    [300] = "#5ABDAC",
    [400] = "#3AA99F",
    [600] = "#24837B",
    [700] = "#1C6C66",
    [800] = "#164F4A",
    [900] = "#122F2C",
    [950] = "#101F1D",
  },
  blue = {
    [50] = "#E1ECEB",
    [100] = "#C6DDE8",
    [200] = "#92BFDB",
    [300] = "#66A0C8",
    [400] = "#4385BE",
    [600] = "#205EA6",
    [700] = "#1A4F8C",
    [800] = "#163B66",
    [900] = "#12253B",
    [950] = "#101A24",
  },
  purple = {
    [50] = "#F0EAEC",
    [100] = "#E2D9E9",
    [200] = "#C4B9E0",
    [300] = "#A699D0",
    [400] = "#8B7EC8",
    [600] = "#5E409D",
    [700] = "#4F3685",
    [800] = "#3C2A62",
    [900] = "#261C39",
    [950] = "#1A1623",
  },
  magenta = {
    [50] = "#FEE4E5",
    [100] = "#FCCFDA",
    [200] = "#F4A4C2",
    [300] = "#E47DA8",
    [400] = "#CE5D97",
    [600] = "#A02F6F",
    [700] = "#87285E",
    [800] = "#641F46",
    [900] = "#39172B",
    [950] = "#24131D",
  },
}

local function luminance(hex)
  local channels = {}
  for i = 2, 6, 2 do
    local v = tonumber(hex:sub(i, i + 1), 16) / 255
    channels[#channels + 1] = v <= 0.04045 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return channels[1] * 0.2126 + channels[2] * 0.7152 + channels[3] * 0.0722
end

function M.contrast(a, b)
  local x, y = luminance(a), luminance(b)
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

local function readable(ramp, stops, backgrounds)
  for _, stop in ipairs(stops) do
    local color = ramp[stop]
    local passes = true
    for _, bg in ipairs(backgrounds) do
      passes = passes and M.contrast(color, bg) >= 4.5
    end
    if passes then
      return color
    end
  end
  error("Flexoki: no readable palette stop")
end

function M.get(background)
  local dark = (background or vim.o.background) == "dark"
  local b, a = M.base, M.accents
  local c = {
    bg = dark and b.black or b.paper,
    bg2 = dark and b[950] or b[50],
    ui = dark and b[900] or b[100],
    ui2 = dark and b[850] or b[150],
    ui3 = dark and b[800] or b[200],
    tx = dark and b[200] or b.black,
    tx2 = dark and b[500] or b[600],
    tx3 = dark and b[700] or b[300],
    tint = {},
  }
  for name, ramp in pairs(a) do
    c.tint[name] = ramp[dark and 950 or 50]
  end
  c.selection = a.blue[dark and 900 or 100]
  c.search = a.yellow[dark and 900 or 100]
  c.diff_text = a.blue[dark and 900 or 100]

  -- Start at the recommended 400/600. Move along the official ramp only
  -- when text would fall below 4.5:1, including on floats and diff lines.
  -- Faint tx3 is reserved for decoration, not comments or filenames.
  local surfaces = { c.bg, c.bg2 }
  for _, tint in pairs(c.tint) do
    surfaces[#surfaces + 1] = tint
  end
  local stops = dark and { 400, 300, 200 } or { 600, 700, 800 }
  for name, ramp in pairs(a) do
    c[name] = readable(ramp, stops, surfaces)
  end
  c.muted = readable(b, dark and { 500, 400, 300 } or { 600, 700, 800 }, surfaces)
  return c
end

return M
