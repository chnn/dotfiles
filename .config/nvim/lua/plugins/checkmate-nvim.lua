return {
  "bngarren/checkmate.nvim",
  ft = "markdown",
  opts = {
    files = { "*.md" },
    keys = {
      ["<leader>x"] = {
        rhs = "<cmd>Checkmate toggle<CR>",
        desc = "Toggle todo item",
        modes = { "n", "v" },
      },
      ["<leader>n"] = {
        rhs = "<cmd>Checkmate create<CR>",
        desc = "Create todo item",
        modes = { "n", "v" },
      },
    },
  },
}
