local function unused_plugins()
  return vim
    .iter(vim.pack.get(nil, { info = false }))
    :filter(function(plugin)
      return not plugin.active
    end)
    :map(function(plugin)
      return plugin.spec.name
    end)
    :totable()
end

vim.api.nvim_create_user_command("PackUnused", function()
  vim.print(unused_plugins())
end, { desc = "List plugins not added in the current session" })

vim.api.nvim_create_user_command("PackClean", function()
  vim.pack.del(unused_plugins())
end, { desc = "Remove inactive plugins from disk and the lockfile" })
