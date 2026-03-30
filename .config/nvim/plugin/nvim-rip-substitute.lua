vim.pack.add({ "https://github.com/chrisgrieser/nvim-rip-substitute" })

require("rip-substitute").setup({
  popupWin = {
    title = "Substitute",
    hideSearchReplaceLabels = true,
    hideKeymapHints = true,
  },
  editingBehavior = { autoCaptureGroups = true },
  notification = { onSuccess = false },
})

vim.keymap.set({ "n", "x" }, "<leader>s", function()
  require("rip-substitute").sub()
end, { desc = "Substitute current selection" })
