return {
  "preservim/vim-markdown",
  ft = "markdown",
  config = function()
    vim.g.vim_markdown_new_list_item_indent = 2
    vim.g.vim_markdown_math = 1
    vim.g.vim_markdown_frontmatter = 1
  end,
}
