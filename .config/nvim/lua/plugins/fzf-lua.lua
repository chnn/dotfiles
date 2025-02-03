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
    local working_dirs = nil

    local set_working_dirs = function(dirs)
      working_dirs = dirs
    end

    local get_working_dirs = function()
      if working_dirs == nil then
        return {}
      else
        return working_dirs
      end
    end

    function escape_for_bash(path)
      path = path:gsub("([%s%$%&%`\"'\\%(%);<>|])", "\\%1")
      return path
    end

    local get_working_dirs_str = function()
      local dirs = get_working_dirs()

      if #dirs == 0 then
        return ""
      end

      local result = ""

      for i = 1, #dirs do
        result = result .. " " .. escape_for_bash(dirs[i])
      end

      return result
    end

    vim.keymap.set("n", "<leader>f", function()
      fzf.files({ cmd = "fd -tf . " .. get_working_dirs_str() })
    end, { silent = true, desc = "Show scoped file picker" })

    vim.keymap.set("n", "<leader>F", function()
      fzf.files({ cmd = "fd ." })
    end, { silent = true, desc = "Show file picker" })

    vim.keymap.set("n", "<leader>c", function()
      fzf.fzf_exec("fd -td", {
        fzf_opts = {
          ["--multi"] = true,
        },
        actions = {
          ["default"] = function(selected)
            set_working_dirs(selected)
          end,
        },
      })
    end, { silent = true, desc = "Scope file picker to subdirectories" })

    vim.keymap.set("n", "<leader>b", ":FzfLua buffers<CR>", { silent = true, desc = "Show buffer picker" })
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
