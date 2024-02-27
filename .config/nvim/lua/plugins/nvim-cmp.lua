return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/vim-vsnip",
    "hrsh7th/vim-vsnip-integ",
    "hrsh7th/cmp-vsnip",
  },
  config = function()
    local cmp = require("cmp")
    local completeopt = "menu,menuone,noinsert,preview"

    local buffer = {
      name = "buffer",
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
      },
    }

    cmp.setup({
      completion = { completeopt = completeopt },

      sources = cmp.config.sources({
        buffer,
      }, {
        { name = "nvim_lsp" },
        buffer,
        { name = "path" },
      }),

      snippet = {
        expand = function(args)
          vim.fn["vsnip#anonymous"](args.body)
        end,
      },

      mapping = {
        ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item()),
        ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item()),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-e>"] = cmp.mapping.abort(),
      },
    })

    cmp.setup.filetype("markdown", { sources = {} })
    cmp.setup.filetype("text", { sources = {} })

    vim.o.completeopt = completeopt
    vim.o.updatetime = 300
  end,
}
