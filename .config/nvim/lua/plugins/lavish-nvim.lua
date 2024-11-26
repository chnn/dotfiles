return {
  "ferdinandrau/lavish.nvim",
  config = function()
    vim.o.background = "dark"
    require("lavish").setup({
      style = {
        transparent = true,
      },
    })

    require("lavish").apply()
  end,
}
