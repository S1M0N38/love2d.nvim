---@module 'luassert'

local config = require("love2d.config")

describe("config", function()
  after_each(function()
    config.options = {}
  end)

  describe("defaults", function()
    it("has path_to_love_bin = 'love'", function()
      assert.are.equal("love", config.defaults.path_to_love_bin)
    end)
  end)

  describe("setup()", function()
    it("merges empty opts with defaults", function()
      config.setup({})
      assert.are.equal("love", config.options.path_to_love_bin)
    end)

    it("merges nil opts with defaults", function()
      config.setup(nil)
      assert.are.equal("love", config.options.path_to_love_bin)
    end)

    it("overrides path_to_love_bin", function()
      config.setup({ path_to_love_bin = "/usr/bin/love" })
      assert.are.equal("/usr/bin/love", config.options.path_to_love_bin)
    end)

    it("preserves defaults for unspecified keys when overriding one", function()
      config.setup({ path_to_love_bin = "/custom/love" })
      assert.are.equal("/custom/love", config.options.path_to_love_bin)
      assert.is_nil(config.options.output)
    end)

    it("accepts output = false", function()
      config.setup({ output = false })
      assert.is_false(config.options.output)
      assert.are.equal("love", config.options.path_to_love_bin)
    end)

    it("accepts output as a table", function()
      config.setup({ output = { width = 80 } })
      assert.are.equal(80, config.options.output.width)
    end)
  end)
end)
