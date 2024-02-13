return {
  {
    "junegunn/goyo.vim",
    dependencies = { "reedes/vim-pencil" },
    config = function()
      vim.keymap.set("n", "<leader>z", ":Goyo<CR>", { silent = true, desc = "Toggle focus mode" })
      vim.cmd([[let g:pencil#conceallevel = 2]])
      vim.cmd([[
        function! s:goyo_enter()
          call pencil#init({'wrap': 'soft'})
          lua require('lualine').hide()
          hi clear StatusLine " Fix ^^^ from showing at bottom of buffer
        endfunction

        function! s:goyo_leave()
          call pencil#init({'wrap': 'off'})
        endfunction

        augroup GoyoSettings
          autocmd!
          autocmd! User GoyoEnter nested call <SID>goyo_enter()
          autocmd! User GoyoLeave nested call <SID>goyo_leave()
        augroup end
      ]])
    end,
  },
}
