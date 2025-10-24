-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())
local interestingBlocks = {
    "minecraft:diamond_ore",
    "minecraft:gold_ore",
    "minecraft:emerald_ore",
    "minecraft:iron_ore",
    "minecraft:coal_ore",
    "minecraft:redstone_ore",
    "minecraft:lapis_ore",
}
local blockIsInteresting = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:coal_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:lapis_ore"] = true,
}


local kaivaSuoni = function()
    local suoniKaivaja = SuoniKaivaja.new(tracker, interestingBlocks)
    suoniKaivaja:aloita()
end

local nopeaTsekkaus = function()
    -- katso ylös, alas ja eteenpäin, palauta true jos mielenkiintoinen blokki löytyy
    for _, dir in ipairs({"forward", "up", "down"}) do
        local ok, data
        if dir == "forward" then
            ok, data = tracker:inspect()
            if ok and blockIsInteresting[data.name] then
                print("Löytyi mielenkiintoinen blokki eteen: "..data.name)
                return true
            end
        elseif dir == "up" then
            ok, data = tracker:inspectUp()
            if ok and blockIsInteresting[data.name] then
                print("Löytyi mielenkiintoinen blokki ylhäällä: "..data.name)
                return true
            end
        elseif dir == "down" then
            ok, data = tracker:inspectDown()
            if ok and blockIsInteresting[data.name] then
                print("Löytyi mielenkiintoinen blokki alhaalla: "..data.name)
                return true
            end
        end
    end
    return false
end


function meneTakaisin()
    print("Mene takaisin lähtöpisteeseen.")
    while true do
        success = tracker:back()
        if not success then
            break
        end
    end
end

-- Pääsilmukka: kaiva tunnelia eteenpäin
stop = false
while true do
    if stop then
        break
    end
    tracker:cycle(function()
        -- siksak
        tracker:safeForward()
        tracker:turnRight()
        tracker:safeForward()
        nopeaTsekkaus()
        tracker:turnLeft()
        tracker:safeForward()
        tracker:turnLeft()
        tracker:safeForward()
        nopeaTsekkaus()
        tracker:turnRight()
        if not (utils.refuel()) then
            print("Ei polttoainetta, palataan takaisin.")
            meneTakaisin()
            stop = true
            return
        end
    end)
end