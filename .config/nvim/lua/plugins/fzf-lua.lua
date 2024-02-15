return {
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

    vim.keymap.set("n", "<leader>f", ":FzfLua files<CR>", { silent = true, desc = "Show file picker" })
    vim.keymap.set("n", "<leader>b", ":FzfLua buffers<CR>", { silent = true, desc = "Show buffer picker" })
    vim.keymap.set("n", "<leader>l", ":FzfLua live_grep<CR>", { silent = true, desc = "Show live grep picker" })
    vim.keymap.set(
      "n",
      "<leader>s",
      ":FzfLua lsp_document_symbols<CR>",
      { silent = true, desc = "Show document symbol picker" }
    )
    vim.keymap.set(
      "n",
      "<leader>S",
      ":FzfLua lsp_workspace_symbols<CR>",
      { silent = true, desc = "Show workspace symbol picker" }
    )
    vim.keymap.set(
      "n",
      "<leader>d",
      ":FzfLua diagnostics_document<CR>",
      { silent = true, desc = "Show document diagnostics picker" }
    )
    vim.keymap.set(
      "n",
      "<leader>D",
      ":FzfLua diagnostics_workspace<CR>",
      { silent = true, desc = "Show workspace diagnostics picker" }
    )

    vim.keymap.set("n", "<leader>,", function()
      fzf.files({ cmd = "fd", cwd = "~/.config/nvim" })
    end, { desc = "Edit Neovim config" })
  end,
}
