vim.pack.add({ "https://github.com/folke/snacks.nvim" })

local Snacks = require("snacks")

Snacks.setup({
  bigfile = { enabled = true },
  notifier = { enabled = true },
  picker = {
    sources = {
      gh_issue = {},
      gh_pr = {},
    },
    layout = { preset = "ivy_split" },
    formatters = {
      file = { truncate = 80 },
    },
    icons = {
      files = { enabled = false },
    },
    win = {
      input = {
        keys = {
          ["<Esc>"] = { "close", mode = { "n", "i" } },
          ["<C-u>"] = { "<C-o>cc", mode = { "i" }, expr = true },
        },
      },
    },
  },
  gh = {},
})

vim.keymap.set("n", "gd", function()
  Snacks.picker.lsp_definitions()
end, { desc = "Go to definition" })

vim.keymap.set("n", "gi", function()
  Snacks.picker.lsp_implementations()
end, { desc = "Go to implementation" })

vim.keymap.set("n", "gy", function()
  Snacks.picker.lsp_type_definitions()
end, { desc = "Go to type definition" })

vim.keymap.set("n", "gs", function()
  Snacks.picker.lsp_symbols({
    filter = {
      default = true,
    },
  })
end, { desc = "Go to symbol" })

vim.keymap.set("n", "<D-p>", function()
  Snacks.picker.smart({ hidden = true })
end, { desc = "Open smart file picker" })

vim.keymap.set("n", "<space>b", function()
  Snacks.picker.buffers()
end, { desc = "Open buffer picker" })

vim.keymap.set("n", "<space>F", function()
  Snacks.picker.files({ hidden = true })
end, { desc = "Open file picker" })

vim.keymap.set("n", "<space>/", function()
  Snacks.picker()
end, { desc = "Open pickers picker" })

vim.keymap.set("n", "<space>,", function()
  Snacks.picker.files({
    hidden = true,
    dirs = { "~/.config/nvim" },
  })
end, { desc = "Edit config" })

vim.keymap.set("n", "<space>r", function()
  Snacks.picker.resume()
end, { desc = "Resume last picker" })

-- JS/TS import search keybinding
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact" },
  callback = function(args)
    vim.keymap.set("n", "<leader>i", function()
      local target_buf = vim.api.nvim_get_current_buf()
      local target_win = vim.api.nvim_get_current_win()
      local word = vim.fn.expand("<cword>")

      Snacks.picker.grep({
        search = "import.*" .. word,
        confirm = function(picker, item)
          if not item then
            return
          end

          picker:close()

          local line_text = item.text or ""
          local content = line_text:match("^[^:]+:%d+:%d+:(.*)$")
          if not content then
            return
          end

          vim.api.nvim_set_current_win(target_win)
          vim.api.nvim_set_current_buf(target_buf)

          vim.api.nvim_buf_set_lines(target_buf, 0, 0, false, { content })
        end,
      })
    end, { desc = "Search and paste import strings", buffer = args.buf })
  end,
})
