return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      filetypes = {
        typescript = true,
        typescriptreact = true,
        ["."] = false,
      },
    })
  end,
}
