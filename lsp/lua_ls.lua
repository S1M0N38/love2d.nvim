return {
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        disable = { "duplicate-set-field" },
      },
      workspace = {
        checkThirdParty = false,
      },
    },
  },
}
