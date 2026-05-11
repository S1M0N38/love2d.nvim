local config = {}

config.defaults = {
  path_to_love_bin = "love",
  output = nil,
}

---@type Love2D.Config
---This table will be populated by user options merged with defaults
config.options = {}

config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})
end

return config
