return {
  "junegunn/goyo.vim",
  config = function()
    vim.keymap.set("n", "<leader>z", ":Goyo<CR>", { silent = true, desc = "Toggle focus mode" })
    vim.cmd([[
        function! s:goyo_enter()
          lua require('lualine').hide()
          hi clear StatusLine
          setlocal linebreak
          setlocal wrap
        endfunction

        function! s:goyo_leave()
          setlocal nowrap
        endfunction

        augroup GoyoSettings
          autocmd!
          autocmd! User GoyoEnter nested call <SID>goyo_enter()
          autocmd! User GoyoLeave nested call <SID>goyo_leave()
        augroup end
        ]])
  end,
}
