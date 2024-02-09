local docgen = require("docgen")

local docs = {}

docs.test = function()
  -- Filepaths that should generate docs
  local input_files = {
    "./lua/my_awesome_plugin/init.lua",
    "./lua/my_awesome_plugin/config.lua",
    "./lua/my_awesome_plugin/math.lua",
  }

  -- Maybe sort them that depends what you want and need
  table.sort(input_files, function(a, b)
    return #a < #b
  end)

  -- Output file
  local output_file = "./doc/my_awesome_plugin.txt"
  local output_file_handle = io.open(output_file, "w")
  assert(output_file_handle, "Could not open " .. output_file)

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, output_file_handle)
  end

  output_file_handle:write(" vim:tw=78:ts=8:ft=help:norl:\n")
  output_file_handle:close()
  vim.cmd([[checktime]])
end

docs.test()

return docs
