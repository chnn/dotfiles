vim.pack.add({ "https://github.com/folke/flash.nvim" })

require("flash").setup({
  modes = {
    treesitter = { label = { after = false } },
    char = { enabled = false },
  },
})

vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter Search" })
