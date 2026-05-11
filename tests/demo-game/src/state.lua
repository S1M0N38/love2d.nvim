-- src/state.lua — simple state manager
local State = {}
State.current = nil

function State.switch(to, ...)
  if State.current and State.current.leave then
    State.current:leave()
  end
  State.current = to
  if to and to.enter then
    to:enter(...)
  end
end

return State
