---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "S1M0N38"
package = "love2d.nvim"

description = {
  summary = "A simple Neovim plugin to build games with LÖVE ",
  labels = { "neovim" },
  homepage = "https://github.com/" .. user .. "/" .. package,
  license = "MIT",
}

source = {
  url = "git://github.com/" .. user .. "/" .. package,
}

build = {
  type = "builtin",
}
