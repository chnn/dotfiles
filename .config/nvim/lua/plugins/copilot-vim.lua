return {

  "github/copilot.vim",
  config = function()
    vim.keymap.set("i", "<M-\\>", "<CMD>Copilot panel<CR>", { silent = true, desc = "Show Copilot suggestions" })
    vim.cmd([[let g:copilot_filetypes = { '*': v:false }]])
  end,
}
