local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")

local label = utils.getLabel()
if label then
    print("Reset: " .. label)
    Actions.reset()
else
  print("Ei labelia!")
end
