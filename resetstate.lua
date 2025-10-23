local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")

local label = utils.getLabel()
if label then
    print("Reset: " .. label)
    tracker = Actions.new(label)
    tracker:completeCycle()
else
  print("Ei labelia!")
end
