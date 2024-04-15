return {
  "github/copilot.vim",
  config = function()
    vim.cmd([[let g:copilot_filetypes = { '*': v:false }]])
  end,
}
