local M = {}

function M.extend(groups, links, c)
  local plugin_links = {
    -- Snacks: avoid NonText for paths, descriptions and other actual text.
    SnacksNormal = "NormalFloat",
    SnacksNormalNC = "NormalFloat",
    SnacksWinBar = "WinBar",
    SnacksWinBarNC = "WinBarNC",
    SnacksTitle = "FloatTitle",
    SnacksFooter = "FloatFooter",
    SnacksWinSeparator = "WinSeparator",
    SnacksFooterKey = "Special",
    SnacksFooterDesc = "Comment",
    SnacksWinKey = "Special",
    SnacksWinKeyDesc = "FlexokiText",
    SnacksWinKeySep = "Delimiter",
    SnacksPickerMatch = "FlexokiMatch",
    SnacksPickerSearch = "Search",
    SnacksPickerPrompt = "Title",
    SnacksPickerInputSearch = "String",
    SnacksPickerFile = "FlexokiText",
    SnacksPickerDirectory = "Directory",
    SnacksPickerDir = "Comment",
    SnacksPickerPathHidden = "Comment",
    SnacksPickerPathIgnored = "Comment",
    SnacksPickerDimmed = "Comment",
    SnacksPickerDesc = "Comment",
    SnacksPickerComment = "Comment",
    SnacksPickerTotals = "Comment",
    SnacksPickerUnselected = "Comment",
    SnacksPickerSelected = "DiagnosticOk",
    SnacksPickerTree = "NonText",
    SnacksPickerRow = "Number",
    SnacksPickerCol = "Comment",
    SnacksPickerBufFlags = "Comment",
    SnacksPickerKeymapRhs = "Comment",
    SnacksPickerGitStatusAdded = "Added",
    SnacksPickerGitStatusStaged = "Added",
    SnacksPickerGitStatusModified = "Changed",
    SnacksPickerGitStatusDeleted = "Removed",
    SnacksPickerGitStatusRenamed = "DiagnosticInfo",
    SnacksPickerGitStatusCopied = "DiagnosticInfo",
    SnacksPickerGitStatusUntracked = "DiagnosticWarn",
    SnacksPickerGitStatusIgnored = "Comment",
    SnacksPickerGitStatusUnmerged = "DiagnosticError",
    SnacksPickerGitStatus = "Comment",
    SnacksPickerGitBranch = "Identifier",
    SnacksPickerGitBranchCurrent = "Title",
    SnacksPickerGitCommit = "Constant",
    SnacksPickerGitDate = "Comment",
    SnacksPickerGitAuthor = "Identifier",
    SnacksPickerGitMsg = "FlexokiText",
    SnacksPickerGitBreaking = "DiagnosticError",
    SnacksInputNormal = "NormalFloat",
    SnacksInputBorder = "FloatBorder",
    SnacksInputTitle = "FloatTitle",
    SnacksInputIcon = "Special",
    SnacksInputPrompt = "Title",
    SnacksDashboardNormal = "Normal",
    SnacksDashboardHeader = "Title",
    SnacksDashboardFooter = "Comment",
    SnacksDashboardDesc = "FlexokiText",
    SnacksDashboardKey = "Special",
    SnacksDashboardIcon = "Identifier",
    SnacksDashboardDir = "Comment",
    SnacksDashboardFile = "FlexokiText",
    SnacksDashboardSpecial = "Special",
    SnacksDashboardTitle = "Title",
    SnacksDashboardTerminal = "Normal",
    SnacksNotifierHistory = "NormalFloat",
    SnacksNotifierHistoryTitle = "Title",
    SnacksNotifierHistoryDateTime = "Comment",
    SnacksNotifierMinimal = "NormalFloat",
    SnacksIndentBlank = "SnacksIndent",
    SnacksIndentChunk = "SnacksIndentScope",
    SnacksScope = "SnacksIndentScope",
    SnacksZenIcon = "Comment",
    SnacksStatusColumnMark = "Special",
    SnacksGhGreen = "Added",
    SnacksGhRed = "Removed",
    SnacksGhPurple = "Number",
    SnacksGhGray = "Comment",
    SnacksGhBotBadge = "Comment",
    SnacksGhStat = "Comment",
    SnacksGhDiffAddLineNr = "Added",
    SnacksGhDiffDeleteLineNr = "Removed",
    SnacksGhDiffContextLineNr = "Comment",

    -- Fugitive status, inline patches, blame and commit buffers.
    fugitiveHeader = "Title",
    fugitiveHelpHeader = "Comment",
    fugitiveHelpTag = "Underlined",
    fugitiveHeading = "Title",
    fugitiveUntrackedHeading = "DiagnosticWarn",
    fugitiveUnstagedHeading = "DiagnosticWarn",
    fugitiveStagedHeading = "DiagnosticOk",
    fugitiveModifier = "Identifier",
    fugitiveUntrackedModifier = "DiagnosticWarn",
    fugitiveUnstagedModifier = "DiagnosticWarn",
    fugitiveStagedModifier = "DiagnosticOk",
    fugitiveSymbolicRef = "Identifier",
    fugitiveHash = "Constant",
    fugitiveCount = "Number",
    fugitiveInstruction = "Keyword",
    fugitiveDone = "Added",
    fugitiveStop = "Removed",
    gitcommitSummary = "FlexokiText",
    gitcommitComment = "Comment",
    gitcommitOverflow = "DiagnosticError",
    gitcommitUntracked = "Comment",
    gitcommitDiscarded = "Comment",
    gitcommitSelected = "Comment",
    gitcommitHeader = "Title",
    gitcommitBranch = "Identifier",
    gitcommitUntrackedFile = "DiagnosticWarn",
    gitcommitSelectedFile = "Added",
    gitcommitDiscardedFile = "Removed",
    gitcommitSelectedType = "Added",
    gitcommitDiscardedType = "Removed",
    gitcommitUnmergedFile = "DiagnosticError",
    gitcommitUnmergedType = "DiagnosticError",
    gitcommitNoBranch = "DiagnosticWarn",
    gitcommitType = "Keyword",
    gitHash = "Constant",
    gitIdentity = "Identifier",
    gitDate = "Comment",
    gitReference = "Identifier",
    FugitiveblameHash = "Constant",
    FugitiveblameAnnotation = "Identifier",
    FugitiveblameTime = "Comment",
    FugitiveblameLineNumber = "Number",
    FugitiveblameOriginalLineNumber = "Number",
    FugitiveblameOriginalFile = "Directory",
    FugitiveblameBoundary = "Comment",
    FugitiveblameBoundaryIgnore = "Comment",
    FugitiveblameUncommitted = "Comment",
    FugitiveblameNotCommittedYet = "Comment",

    -- Diffview is already installed in these dotfiles; share Git semantics.
    DiffviewFilePanelInsertions = "Added",
    DiffviewFilePanelDeletions = "Removed",
    DiffviewFilePanelSelected = "Title",
    DiffviewFilePanelPath = "Comment",
    DiffviewStatusAdded = "Added",
    DiffviewStatusUntracked = "DiagnosticWarn",
    DiffviewStatusModified = "Changed",
    DiffviewStatusRenamed = "Changed",
    DiffviewStatusCopied = "Added",
    DiffviewStatusDeleted = "Removed",
    DiffviewStatusUnmerged = "DiagnosticError",
    DiffviewStatusIgnored = "Comment",
    DiffviewDiffDeleteDim = "Comment",
  }
  for name, target in pairs(plugin_links) do
    links[name] = target
  end
  -- Inline text must not carry a background that masks the selected row.
  groups.FlexokiText = { fg = c.tx }
  groups.FlexokiMatch = { fg = c.cyan, bold = true, underline = true }
  groups.SnacksIndent = { fg = c.ui }
  groups.SnacksIndentScope = { fg = c.ui3 }
  groups.SnacksGhAssocBadge = { fg = c.bg, bg = c.cyan, bold = true }

  -- Explicit window families also cover split/ivy layouts and lazy loading.
  for _, prefix in ipairs({
    "SnacksPicker",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPreview",
    "SnacksPickerBox",
  }) do
    links[prefix] = "NormalFloat"
    links[prefix .. "Normal"] = "NormalFloat"
    links[prefix .. "Border"] = "FloatBorder"
    links[prefix .. "Title"] = "FloatTitle"
    links[prefix .. "Footer"] = "FloatFooter"
    groups[prefix .. "CursorLine"] = { bg = c.tint.blue, bold = true }
  end
  for _, level in ipairs({ "Error", "Warn", "Info", "Debug", "Trace" }) do
    local target = (level == "Debug" or level == "Trace") and "Comment" or "Diagnostic" .. level
    links["SnacksNotifier" .. level] = "NormalFloat"
    for _, part in ipairs({ "Icon", "Title", "Footer" }) do
      links["SnacksNotifier" .. part .. level] = target
    end
    links["SnacksNotifierBorder" .. level] = "FloatBorder"
  end
end

return M
