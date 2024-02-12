return {
  {
    "ibhagwan/fzf-lua",
    branch = "main",
    config = function()
      local fzf = require("fzf-lua")

      fzf.setup({
        files = { no_header = true },
        buffers = { no_header = true },
        live_grep = { no_header = true },
        winopts = {
          preview = { layout = "vertical" },
        },
      })

      vim.keymap.set("n", "<M-p>", ":FzfLua files<CR>", { silent = true })
      vim.keymap.set("n", "<leader>f", ":FzfLua files<CR>", { silent = true })
      vim.keymap.set("n", "<leader>b", ":FzfLua buffers<CR>", { silent = true })
      vim.keymap.set("n", "<leader>l", ":FzfLua live_grep<CR>", { silent = true })
      vim.keymap.set("n", "<leader>s", ":FzfLua lsp_document_symbols<CR>", { silent = true })
      vim.keymap.set("n", "<leader>S", ":FzfLua lsp_workspace_symbols<CR>", { silent = true })
      vim.keymap.set("n", "<leader>d", ":FzfLua diagnostics_document<CR>", { silent = true })
      vim.keymap.set("n", "<leader>D", ":FzfLua diagnostics_workspace<CR>", { silent = true })

      vim.keymap.set("n", "<leader>,", function()
        fzf.files({ cmd = "fd", cwd = "~/.config/nvim" })
      end, { desc = "Edit Neovim config" })
    end,
  },
}
