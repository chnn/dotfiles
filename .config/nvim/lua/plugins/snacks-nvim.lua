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
    {
      "<space>ng",
      function()
        Snacks.picker.grep({
          dirs = { os.getenv("NOTES") },
        })
      end,
      desc = "Open grep for notes",
    },
    {
      "<space>np",
      function()
        Snacks.picker.files({
          dirs = { os.getenv("NOTES") },
        })
      end,
      desc = "Open a note",
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

    -- Helper to calculate relative path from one directory to a file
    local function get_relative_path(from_dir, to_file)
      from_dir = vim.fn.resolve(from_dir)
      to_file = vim.fn.resolve(to_file)

      local function split_path(path)
        local parts = {}
        for part in path:gmatch("[^/]+") do
          table.insert(parts, part)
        end
        return parts
      end

      local from_parts = split_path(from_dir)
      local to_parts = split_path(to_file)

      local common_len = 0
      for i = 1, math.min(#from_parts, #to_parts) do
        if from_parts[i] == to_parts[i] then
          common_len = i
        else
          break
        end
      end

      local rel_parts = {}
      for _ = common_len + 1, #from_parts do
        table.insert(rel_parts, "..")
      end
      for i = common_len + 1, #to_parts do
        table.insert(rel_parts, to_parts[i])
      end

      return table.concat(rel_parts, "/")
    end

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

    -- Markdown relative file path insertion keybinding
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown" },
      callback = function(args)
        vim.keymap.set("n", "<leader>i", function()
          local target_buf = vim.api.nvim_get_current_buf()
          local target_win = vim.api.nvim_get_current_win()
          local current_file = vim.fn.expand("%:p")
          local current_dir = vim.fn.expand("%:p:h")
          local notes_dir = os.getenv("NOTES")

          local picker_opts = { hidden = true }
          if notes_dir and current_file:find(vim.fn.resolve(notes_dir), 1, true) then
            picker_opts.dirs = { notes_dir }
          end

          Snacks.picker.files(vim.tbl_extend("force", picker_opts, {
            confirm = function(picker, item)
              if not item then
                return
              end

              picker:close()

              local selected_file = item.file
              if not selected_file then
                return
              end

              if not vim.startswith(selected_file, "/") then
                selected_file = vim.fn.getcwd() .. "/" .. selected_file
              end

              local relative = get_relative_path(current_dir, selected_file)

              vim.api.nvim_set_current_win(target_win)
              vim.api.nvim_set_current_buf(target_buf)

              local row, col = unpack(vim.api.nvim_win_get_cursor(target_win))
              local line = vim.api.nvim_buf_get_lines(target_buf, row - 1, row, true)[1]
              local new_line = line:sub(1, col + 1) .. relative .. line:sub(col + 2)
              vim.api.nvim_buf_set_lines(target_buf, row - 1, row, true, { new_line })

              vim.api.nvim_win_set_cursor(target_win, { row, col + #relative })
            end,
          }))
        end, { desc = "Insert relative file path", buffer = args.buf })
      end,
    })
  end,
}
