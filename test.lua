local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())

-- Pääsilmukka: kaiva tunnelia eteenpäin
local last_step = tracker.state.last_step or 0
print("last_step: " .. last_step)

tracker:safeForward()
local suoniKaivaja = SuoniKaivaja.new(tracker, {"minecraft:diamond_ore"}, riittavastiSaplingeja)
suoniKaivaja:aloita()
tracker:safeBack()

shell.run("resetstate.lua")
