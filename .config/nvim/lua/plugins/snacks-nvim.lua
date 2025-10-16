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
        Snacks.picker.smart()
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
        Snacks.picker.files()
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

    local function grep_and_paste()
      local target_buf = vim.api.nvim_get_current_buf()
      local target_win = vim.api.nvim_get_current_win()
      local cursor_pos = vim.api.nvim_win_get_cursor(target_win)

      Snacks.picker.grep({
        confirm = function(picker, item)
          if not item then
            return
          end

          picker:close()

          -- Remove filepath:line:col: prefix to get just the content
          local line_text = item.text or ""
          local content = line_text:match("^[^:]+:%d+:%d+:(.*)$")
          if not content then
            return
          end

          -- Switch back to the target buffer/window
          vim.api.nvim_set_current_win(target_win)
          vim.api.nvim_set_current_buf(target_buf)

          -- Insert the line at the current cursor position and move cursor
          vim.api.nvim_buf_set_lines(target_buf, 0, 0, false, { content })
          vim.api.nvim_win_set_cursor(target_win, { 1, 0 })
        end,
      })
    end

    vim.api.nvim_create_user_command("GrepAndPaste", grep_and_paste, {})
  end,
}
