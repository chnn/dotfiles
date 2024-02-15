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
    local completeopt = "menu,menuone,noinsert,preview"
    vim.o.completeopt = completeopt
    vim.o.updatetime = 300
    local cmp = require("cmp")
    cmp.setup({
      completion = { completeopt = completeopt },

      sources = cmp.config.sources({
        { name = "buffer" },
      }, {
        { name = "nvim_lsp" },
        { name = "buffer" },
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
  end,
}
