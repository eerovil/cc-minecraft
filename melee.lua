local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())

while true do 
    tracker:cycle(function() 
        -- lyö ja käänny
        turtle.attack()
        tracker:turnRight()
    end)
end

shell.run("resetstate.lua")
