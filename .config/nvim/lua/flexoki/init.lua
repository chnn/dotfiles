local M = {}

function M.load(background)
  if background then
    vim.o.background = background
  end
  vim.o.termguicolors = true
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  -- A canonical name lets :set background=… reload either variant naturally.
  vim.g.colors_name = "flexoki"

  local c = require("flexoki.palette").get()
  local groups = {
    Normal = { fg = c.tx, bg = c.bg },
    NormalNC = { fg = c.tx, bg = c.bg },
    NormalFloat = { fg = c.tx, bg = c.bg2 },
    FloatBorder = { fg = c.ui3, bg = c.bg2 },
    FloatTitle = { fg = c.cyan, bg = c.bg2, bold = true },
    FloatFooter = { fg = c.muted, bg = c.bg2 },
    WinSeparator = { fg = c.ui3 },
    SignColumn = { fg = c.muted, bg = c.bg },
    FoldColumn = { fg = c.muted, bg = c.bg },
    Folded = { fg = c.muted, bg = c.bg2 },
    LineNr = { fg = c.muted },
    CursorLineNr = { fg = c.tx, bold = true },
    CursorLine = { bg = c.bg2 },
    CursorColumn = { bg = c.bg2 },
    ColorColumn = { bg = c.bg2 },
    Cursor = { fg = c.bg, bg = c.tx },
    TermCursor = { fg = c.bg, bg = c.cyan },
    NonText = { fg = c.tx3 },
    Whitespace = { fg = c.ui3 },
    EndOfBuffer = { fg = c.ui },
    Conceal = { fg = c.muted },
    Directory = { fg = c.blue },
    Title = { fg = c.cyan, bold = true },
    Visual = { fg = c.tx, bg = c.selection },
    Search = { fg = c.tx, bg = c.search },
    CurSearch = { fg = c.bg, bg = c.orange, bold = true },
    IncSearch = { fg = c.bg, bg = c.orange, bold = true },
    MatchParen = { fg = c.cyan, bold = true, underline = true },
    Substitute = { fg = c.bg, bg = c.red, bold = true },
    Pmenu = { fg = c.tx, bg = c.bg2 },
    PmenuSel = { fg = c.tx, bg = c.selection, bold = true },
    PmenuSbar = { bg = c.ui },
    PmenuThumb = { bg = c.ui3 },
    PmenuMatch = { fg = c.cyan, bold = true },
    PmenuMatchSel = { fg = c.tx, bg = c.selection, bold = true, underline = true },
    StatusLine = { fg = c.tx, bg = c.bg2 },
    StatusLineNC = { fg = c.muted, bg = c.bg2 },
    WinBar = { fg = c.tx, bg = c.bg },
    WinBarNC = { fg = c.muted, bg = c.bg },
    TabLine = { fg = c.muted, bg = c.bg2 },
    TabLineFill = { bg = c.bg2 },
    TabLineSel = { fg = c.cyan, bg = c.bg, bold = true },
    QuickFixLine = { fg = c.tx, bg = c.selection, bold = true },
    ErrorMsg = { fg = c.red, bold = true },
    WarningMsg = { fg = c.orange },
    MoreMsg = { fg = c.green },
    ModeMsg = { fg = c.muted },
    Question = { fg = c.cyan },
    MsgArea = { fg = c.tx, bg = c.bg },
    MsgSeparator = { fg = c.ui3, bg = c.bg2 },
    WildMenu = { fg = c.tx, bg = c.selection },

    -- Flexoki's semantic mappings, shared by regex syntax, Tree-sitter and LSP.
    Comment = { fg = c.muted, italic = true },
    Constant = { fg = c.yellow },
    String = { fg = c.cyan },
    Number = { fg = c.purple },
    Identifier = { fg = c.blue },
    Function = { fg = c.orange },
    Statement = { fg = c.green },
    Operator = { fg = c.muted },
    PreProc = { fg = c.magenta },
    Include = { fg = c.red },
    Type = { fg = c.magenta },
    Special = { fg = c.magenta },
    Delimiter = { fg = c.muted },
    Underlined = { fg = c.cyan, underline = true },
    Ignore = { fg = c.muted },
    Error = { fg = c.red, bg = c.tint.red, bold = true },
    Todo = { fg = c.orange, bg = c.tint.orange, bold = true },
    Bold = { bold = true },
    Italic = { italic = true },

    -- Preserve syntax on changed/added lines. Stronger intraline backgrounds
    -- use primary text instead of putting a weak accent on another accent.
    DiffAdd = { bg = c.tint.green },
    DiffChange = { bg = c.tint.blue },
    DiffDelete = { fg = c.red, bg = c.tint.red },
    DiffText = { fg = c.tx, bg = c.diff_text, bold = true },
    DiffTextAdd = { fg = c.tx, bg = c.tint.green, bold = true, underline = true },
    Added = { fg = c.green },
    Changed = { fg = c.blue },
    Removed = { fg = c.red },
    diffAdded = { fg = c.green, bg = c.tint.green },
    diffRemoved = { fg = c.red, bg = c.tint.red },
    diffChanged = { fg = c.blue, bg = c.tint.blue },
    diffLine = { fg = c.cyan, bold = true },
    diffFile = { fg = c.blue, bold = true },
    diffIndexLine = { fg = c.muted },

    LspReferenceText = { underline = true, sp = c.cyan },
    LspInlayHint = { fg = c.muted, bg = c.bg2 },
    LspCodeLens = { fg = c.muted },
    LspSignatureActiveParameter = { fg = c.orange, bold = true, underline = true },

    ["@none"] = {},
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.quote"] = { fg = c.muted, italic = true },
    ["@markup.raw"] = { fg = c.cyan },
    ["@markup.math"] = { fg = c.purple },
    ["@markup.link.label"] = { fg = c.cyan, underline = true },
    ["@markup.link.url"] = { fg = c.cyan, underline = true },
    ["@lsp.mod.deprecated"] = { strikethrough = true },
  }

  local links = {
    lCursor = "Cursor",
    CursorIM = "Cursor",
    VisualNOS = "Visual",
    CursorLineSign = "SignColumn",
    CursorLineFold = "FoldColumn",
    LineNrAbove = "LineNr",
    LineNrBelow = "LineNr",
    PmenuKind = "Pmenu",
    PmenuExtra = "Pmenu",
    PmenuKindSel = "PmenuSel",
    PmenuExtraSel = "PmenuSel",
    PmenuBorder = "FloatBorder",
    PmenuShadow = "NormalFloat",
    PmenuShadowThrough = "NormalFloat",
    StatusLineTerm = "StatusLine",
    StatusLineTermNC = "StatusLineNC",
    Character = "String",
    Boolean = "Constant",
    Float = "Number",
    Conditional = "Statement",
    Repeat = "Statement",
    Label = "Statement",
    Keyword = "Statement",
    Exception = "Statement",
    Define = "PreProc",
    Macro = "PreProc",
    PreCondit = "PreProc",
    StorageClass = "Type",
    Structure = "Type",
    Typedef = "Type",
    SpecialChar = "Special",
    Tag = "Type",
    SpecialComment = "Comment",
    Debug = "Special",
    diffOldFile = "diffRemoved",
    diffNewFile = "diffAdded",
    diffSubname = "diffLine",
    diffNoEOL = "Comment",
    diffComment = "Comment",
    LspReferenceRead = "LspReferenceText",
    LspReferenceWrite = "LspReferenceText",
    LspCodeLensSeparator = "LspCodeLens",
    SnippetTabstop = "Visual",

    ["@comment"] = "Comment",
    ["@comment.documentation"] = "Comment",
    ["@comment.error"] = "DiagnosticError",
    ["@comment.warning"] = "DiagnosticWarn",
    ["@comment.todo"] = "Todo",
    ["@comment.note"] = "DiagnosticInfo",
    ["@variable"] = "Identifier",
    ["@variable.builtin"] = "Special",
    ["@variable.parameter"] = "Identifier",
    ["@variable.parameter.builtin"] = "Special",
    ["@variable.member"] = "Identifier",
    ["@property"] = "Identifier",
    ["@constant"] = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@constant.macro"] = "Constant",
    ["@module"] = "Identifier",
    ["@module.builtin"] = "Special",
    ["@label"] = "Label",
    ["@string"] = "String",
    ["@string.documentation"] = "String",
    ["@string.regexp"] = "String",
    ["@string.escape"] = "SpecialChar",
    ["@string.special"] = "SpecialChar",
    ["@string.special.url"] = "Underlined",
    ["@string.special.path"] = "String",
    ["@string.special.symbol"] = "Constant",
    ["@character"] = "Character",
    ["@character.special"] = "SpecialChar",
    ["@boolean"] = "Boolean",
    ["@number"] = "Number",
    ["@number.float"] = "Float",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@type.definition"] = "Type",
    ["@type.qualifier"] = "Keyword",
    ["@attribute"] = "Identifier",
    ["@attribute.builtin"] = "Special",
    ["@function"] = "Function",
    ["@function.builtin"] = "Function",
    ["@function.call"] = "Function",
    ["@function.macro"] = "Function",
    ["@function.method"] = "Function",
    ["@function.method.call"] = "Function",
    ["@constructor"] = "Type",
    ["@operator"] = "Operator",
    ["@keyword"] = "Keyword",
    ["@keyword.import"] = "Include",
    ["@keyword.directive"] = "PreProc",
    ["@keyword.directive.define"] = "PreProc",
    ["@keyword.operator"] = "Operator",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "Delimiter",
    ["@punctuation.special"] = "Special",
    -- JSX/TSX queries distinguish intrinsic elements from React components.
    ["@tag"] = "Type",
    ["@tag.builtin"] = "Keyword",
    ["@tag.attribute"] = "Identifier",
    ["@tag.delimiter"] = "Delimiter",
    ["@markup.heading"] = "Title",
    ["@markup.link"] = "Underlined",
    ["@markup.list"] = "Special",
    ["@markup.list.checked"] = "Added",
    ["@markup.list.unchecked"] = "Comment",
    ["@diff.plus"] = "diffAdded",
    ["@diff.minus"] = "diffRemoved",
    ["@diff.delta"] = "diffChanged",
  }

  for severity, color in pairs({ Error = "red", Warn = "orange", Info = "blue", Hint = "cyan", Ok = "green" }) do
    groups["Diagnostic" .. severity] = { fg = c[color] }
    groups["DiagnosticVirtualText" .. severity] = { fg = c[color], bg = c.tint[color] }
    groups["DiagnosticUnderline" .. severity] = { sp = c[color], undercurl = true }
    links["DiagnosticSign" .. severity] = "Diagnostic" .. severity
    links["DiagnosticFloating" .. severity] = "Diagnostic" .. severity
  end
  groups.DiagnosticUnnecessary = { fg = c.muted }
  groups.DiagnosticDeprecated = { strikethrough = true, sp = c.red }
  for kind, color in pairs({ Bad = "red", Cap = "orange", Local = "cyan", Rare = "purple" }) do
    groups["Spell" .. kind] = { sp = c[color], undercurl = true }
  end

  -- Higher-priority semantic tokens should use the same palette as Tree-sitter.
  for token, target in pairs({
    namespace = "@module",
    type = "@type",
    class = "@type",
    enum = "@type",
    interface = "@type",
    struct = "@type",
    typeParameter = "@type",
    parameter = "@variable.parameter",
    variable = "@variable",
    property = "@property",
    enumMember = "@constant",
    event = "@type",
    function_ = "@function",
    method = "@function.method",
    macro = "@function.macro",
    keyword = "@keyword",
    modifier = "@keyword",
    comment = "@comment",
    string = "@string",
    number = "@number",
    regexp = "@string.regexp",
    operator = "@operator",
    decorator = "@attribute",
  }) do
    links["@lsp.type." .. token:gsub("_$", "")] = target
  end
  -- TS servers can classify <Component> as a variable or function and props
  -- as properties. Let JSX captures win instead. LSP suffixes are FILETYPES,
  -- not the Tree-sitter language name "tsx". No parser/query overrides needed.
  for _, ft in ipairs({ "typescriptreact", "javascriptreact" }) do
    for _, token in ipairs({ "variable", "function", "method", "property", "class" }) do
      groups["@lsp.type." .. token .. "." .. ft] = {}
    end
  end

  require("flexoki.plugins").extend(groups, links, c)
  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  for name, target in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = target })
  end

  local b, a = require("flexoki.palette").base, require("flexoki.palette").accents
  local terminal = {
    b[800],
    c.red,
    c.green,
    c.yellow,
    c.blue,
    c.magenta,
    c.cyan,
    b[200],
    c.muted,
    a.red[300],
    a.green[300],
    a.yellow[300],
    a.blue[300],
    a.magenta[300],
    a.cyan[300],
    b.paper,
  }
  -- Avoid invisible ANSI black on ink / bright white on paper. These are
  -- foreground-oriented colors; terminal applications can still set backgrounds.
  if vim.o.background == "light" then
    terminal[8], terminal[16] = c.muted, b.black
    for i = 10, 15 do
      terminal[i] = terminal[i - 8]
    end
  else
    terminal[1], terminal[9] = c.muted, b[400]
  end
  for i, color in ipairs(terminal) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

return M
