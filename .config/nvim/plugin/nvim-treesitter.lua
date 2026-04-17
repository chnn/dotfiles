vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and ev.data.kind ~= "delete" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" } })

require("nvim-treesitter").setup({})

-- Auto-install parsers and enable highlighting
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft) or ft
    if not vim.treesitter.language.add(lang) then
      local ok, task = pcall(require("nvim-treesitter").install, { lang })
      if ok and task then
        pcall(task.wait, task, 60000)
      end
    end
    pcall(vim.treesitter.start, args.buf)
  end,
})
