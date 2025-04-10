return {
  "chrisgrieser/nvim-rip-substitute",
  cmd = "RipSubstitute",
  opts = {},
  keys = {
    {
      "<leader>s",
      function()
        require("rip-substitute").sub()
      end,
      mode = { "n", "x" },
      desc = "Substitute current selection",
    },
  },
  config = function()
    require("rip-substitute").setup({
      popupWin = {
        title = "Substitute",
        hideSearchReplaceLabels = true,
        hideKeymapHints = true,
      },
      editingBehavior = { autoCaptureGroups = true },
      notification = { onSuccess = false },
    })
  end,
}
