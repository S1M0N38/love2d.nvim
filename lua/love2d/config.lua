local config = {}

config.defaults = {
  path_to_love = "love",
}
---@class options
---@field path_to_love string: The path to the Love2D executable
config.options = {}

---@param opts? options: config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})
end

return config
