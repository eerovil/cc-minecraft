local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")

local label = os.getComputerLabel()
if label then
  local role = label:match("^([^_]+)")
  if not role or role == "" then
    print("Ei voitu päätellä roolia nimestä.")
    return
  end

    tracker = Actions.new(role)
    tracker:completeCycle()
end
