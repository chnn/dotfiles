return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        auto_install = true,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        indent = {
          enable = true,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<A-o>",
            node_incremental = "<A-o>",
            scope_incremental = "<A-O>",
            node_decremental = "<A-i>",
          },
        },

        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ic"] = "@comment.inner",
              ["ac"] = "@comment.outer",
              ["ia"] = "@parameter.inner",
              ["aa"] = "@parameter.outer",
            },
          },

          move = {
            enable = true,

            goto_next_start = {
              ["]f"] = "@function.outer",
            },

            goto_next_end = {
              ["]F"] = "@function.outer",
            },

            goto_previous_start = {
              ["[f"] = "@function.outer",
            },

            goto_previous_end = {
              ["[F"] = "@function.outer",
            },
          },
        },
      })
    end,
  },
}
