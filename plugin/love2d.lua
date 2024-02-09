vim.api.nvim_create_user_command("LoveRun", function(args)
  local path = args.args
  local main = ""
  if path == "" then
    main = vim.fn.findfile("main.lua", ".;")
    path = vim.fn.fnamemodify(main, ":h")
  else
    main = vim.fn.findfile("main.lua", path)
  end
  if main == "" then
    vim.notify("No main.lua file found", vim.log.levels.ERROR)
    return
  else
    ---@cast path string
    require("love2d").run(path)
  end
end, { nargs = "?", complete = "dir" })

vim.api.nvim_create_user_command("LoveStop", function(args)
  require("love2d").stop()
end, {})
