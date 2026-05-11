local sub_cmds = {
  run = function()
    require("love2d.job").run()
  end,
  watch = function()
    require("love2d.job").watch()
  end,
  stop = function()
    require("love2d.job").stop()
  end,
  info = function()
    require("love2d.job").info()
  end,
  output = function()
    require("love2d.output").toggle()
  end,
}

local sub_cmds_keys = vim.tbl_keys(sub_cmds)

vim.api.nvim_create_user_command("Love", function(opts)
  local sub_cmd = sub_cmds[opts.args]
  if sub_cmd == nil then
    vim.notify("Love: invalid subcommand", vim.log.levels.ERROR, { title = "love2d" })
  else
    sub_cmd()
  end
end, {
  nargs = "?",
  desc = "LÖVE game runner",
  complete = function(arg_lead, _, _)
    return vim
      .iter(sub_cmds_keys)
      :filter(function(sub_cmd)
        return sub_cmd:find(arg_lead) ~= nil
      end)
      :totable()
  end,
})
