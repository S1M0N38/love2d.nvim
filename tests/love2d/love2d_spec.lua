local love2d = require("love2d")

local opts
if vim.fn.has("mac") == 1 then
  opts = {
    path_to_love = "/Applications/love.app/Contents/MacOS/love",
    path_to_love_library = "",
  }
elseif vim.fn.has("linux") == 1 then
  opts = {
    path_to_love = "love",
    path_to_love_library = "",
  }
else
  error("OS not supported")
end

describe("love2d platform", function()
  it("does not start with wrong path_to_love", function()
    love2d.setup({
      path_to_love = "this/path/does/not/exist/love",
      path_to_love_library = "",
    })
    love2d.run("tests/game")
    vim.wait(1000)
    assert.equal(nil, love2d.job.id)
    vim.wait(500)
  end)
  it("starts", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    assert.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500)
  end)
  it("does not run foo with wrong path to game", function()
    love2d.setup(opts)
    love2d.run("tests/foo")
    vim.wait(1000)
    assert.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500)
    assert.equal(1, love2d.job.exit_code)
  end)
  it("runs game", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    assert.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500) -- wait for on_exit to be called
    assert.equal(0, love2d.job.exit_code)
  end)
  it("stops", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    love2d.stop()
    vim.wait(500)
    assert.equal(nil, love2d.job.id)
    assert.equal(0, love2d.job.exit_code)
  end)
end)
