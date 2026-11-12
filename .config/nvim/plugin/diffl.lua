-- :Diffl [rev] | :Diffl <left> <right>  (see lua/diffl/init.lua)
vim.api.nvim_create_user_command("Diffl", function(opts)
  require("diffl").diffl(opts.fargs)
end, {
  nargs = "*",
  complete = function(arglead)
    return require("diffl").complete(arglead)
  end,
  desc = "Diff revisions (git/jj) into the quickfix list",
})
