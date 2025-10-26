local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())

-- Pääsilmukka: kaiva tunnelia eteenpäin
local last_step = tracker.state.last_step or 0
print("last_step: " .. last_step)

while true do 
    tracker:cycle(function() 
        tracker:safeForward()
        tracker:turnRight()
        tracker:safeForward()
        tracker:turnRight()
        tracker:safeForward()
        tracker:moveTo(0, 0, 0, tracker:startFacingName())
        local success, below = tracker:inspectDown()
        -- jos ei ole timanttikuutioa alla, error
        tracker:log("alla: " .. (below and below.name or "ei mitään"))
        if not (success and below.name == "minecraft:diamond_block") then
        error("Ei timanttia alla!")
        end
    end)
end

shell.run("resetstate.lua")
