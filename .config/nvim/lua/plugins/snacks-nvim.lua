return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Go to definition",
    },
    {
      "gi",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Go to implementation",
    },
    {
      "gy",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Go to type definition",
    },
    {
      "gs",
      function()
        Snacks.picker.lsp_symbols({
          filter = {
            default = true,
          },
        })
      end,
      desc = "Go to type definition",
    },
    {
      "<D-p>",
      function()
        Snacks.picker.smart({ hidden = true })
      end,
      desc = "Open smart file picker",
    },
    {
      "<space>b",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Open buffer picker",
    },
    {
      "<space>F",
      function()
        Snacks.picker.files({ hidden = true })
      end,
      desc = "Open file picker",
    },
    {
      "<space>/",
      function()
        Snacks.picker()
      end,
      desc = "Open pickers picker",
    },
    {
      "<space>,",
      function()
        Snacks.picker.files({
          hidden = true,
          dirs = { "~/.config/nvim" },
        })
      end,
      desc = "Edit config",
    },
    {
      "<space>r",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume last picker",
    },
  },
  config = function()
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
  end,
}
