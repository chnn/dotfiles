return {
  "echasnovski/mini.files",
  version = "*",
  config = function()
    require("mini.files").setup({
      mappings = {
        close = "q",
        go_in_plus = "<CR>",
        go_out = "-",
        go_out_plus = "",
        reset = "<BS>",
        show_help = "g?",
        synchronize = "=",
        reveal_cwd = "",
        go_in = "",
        trim_left = "",
        trim_right = "",
      },
    })
    vim.keymap.set("n", "-", function()
      require("mini.files").open(vim.api.nvim_buf_get_name(0))
    end, { desc = "Open parent directory" })
  end,
}
