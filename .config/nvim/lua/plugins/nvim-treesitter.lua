return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- Auto-install parsers and enable highlighting
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if not pcall(vim.treesitter.language.add, lang) then
            pcall(require("nvim-treesitter").install, { lang })
          end
          pcall(vim.treesitter.start, args.buf, lang)
        end,
      })
    end,
  },
  {
    "daliusd/incr.nvim",
    opts = {
      incr_key = "<A-o>",
      decr_key = "<A-i>",
    },
  },
}
