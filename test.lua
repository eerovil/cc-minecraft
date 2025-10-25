local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())

-- Pääsilmukka: kaiva tunnelia eteenpäin
local last_step = tracker.state.last_step or 0
print("last_step: " .. last_step)

tracker:safeForward()
tracker:safeForward()
tracker:turnRight()
tracker:safeForward()
tracker:turnRight()
tracker:safeForward()
tracker:moveTo(0, 0, 0, tracker:startFacingName())

shell.run("resetstate.lua")
