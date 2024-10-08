return {
  "ibhagwan/fzf-lua",
  branch = "main",
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      files = { no_header = true, git_icons = false },
      buffers = { no_header = true, git_icons = false },
      live_grep = { no_header = true, git_icons = false },
      winopts = {
        preview = { layout = "vertical" },
      },
    })

    -- File picker
    local files_cwd = nil
    vim.keymap.set("n", "<leader>f", function()
      fzf.files({ cwd = files_cwd })
    end, { silent = true, desc = "Show file picker" })
    vim.keymap.set("n", "<leader>F", function()
      fzf.files()
    end, { silent = true, desc = "Show file picker" })
    vim.keymap.set("n", "<leader>c", function()
      fzf.fzf_exec("fd --type d", {
        actions = {
          ["default"] = function(selected)
            files_cwd = selected[1]
          end,
        },
      })
    end, { silent = true, desc = "Scope file picker to subdirectory" })

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
    vim.keymap.set(
      "n",
      "<leader>a",
      ":FzfLua lsp_code_actions<CR>",
      { silent = true, desc = "Show available code actions" }
    )
    vim.keymap.set(
      "n",
      "<leader>:",
      ":FzfLua command_history<CR>",
      { silent = true, desc = "Show command history picker" }
    )
    vim.keymap.set("n", "<leader>/", ":FzfLua builtin<CR>", { silent = true, desc = "Show pickers picker" })

    vim.keymap.set("n", "<leader>,", function()
      fzf.files({ cmd = "fd", cwd = "~/.config/nvim" })
    end, { desc = "Edit Neovim config" })
  end,
}
