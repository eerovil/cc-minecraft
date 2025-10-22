-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
tracker = Actions.new("miner")

-- funktio: kerro onko blokki mielenkiintoinen
local function isInterestingBlock(blockName)
    local interestingBlocks = {
        "minecraft:diamond_ore",
        "minecraft:gold_ore",
        "minecraft:emerald_ore",
        "minecraft:iron_ore",
        "minecraft:coal_ore",
        "minecraft:redstone_ore",
        "minecraft:lapis_ore",
    }
    for _, name in ipairs(interestingBlocks) do
        if blockName == name then
            return true
        end
    end
    return false
end


-- Etukäteisviittaukset funktioihin, jotta rekursio toimii
local inspectSurroundings, kaivaSuoni

kaivaSuoni = function(direction)
    if direction == "up" then
        tracker:digUp()
        tracker:up()
        inspectSurroundings()
        tracker:down()
    elseif direction == "down" then
        tracker:digDown()
        tracker:down()
        inspectSurroundings()
        tracker:up()
    elseif direction == "forward" then
        tracker:dig()
        tracker:safeForward()
        inspectSurroundings()
        tracker:back()
    end
end

inspectSurroundings = function()
    -- ensin katso ylös
    local successUp, dataUp = turtle:inspectUp()
    if successUp and isInterestingBlock(dataUp.name) then
        print("Yläpuolella: " .. (dataUp.name or "tuntematon"))
        kaivaSuoni("up")
    end
    -- sitten katso alas
    local successDown, dataDown = turtle:inspectDown()
    if successDown and isInterestingBlock(dataDown.name) then
        print("Alapuolella: " .. (dataDown.name or "tuntematon"))
        kaivaSuoni("down")
    end
    -- sitten katso eteen
    local successAhead, dataDown = turtle:inspect()
    if successAhead and isInterestingBlock(dataDown.name) then
        print("Alapuolella: " .. (dataDown.name or "tuntematon"))
        kaivaSuoni("down")
    end
    print("Ei mielenkiintoista ympärillä.")
    return nil
end

local kaiva = function(eitsekkaa)
    utils.refuel()
    -- ennen kaivamista, tarkista ympäristö
    if not eitsekkaa then
        inspectSurroundings()
    end
    tracker:dig()
    -- jos yläpuolella on soihtu, älä kaiva sitä pois
    local successUp, dataUp = turtle.inspectUp()
    -- jos nimessä on teksti "torch"
    if successUp and string.find(dataUp.name, "torch") then
        print("Soihtu yläpuolella, jätetään se rauhaan.")
        return
    end
end

local laitaSoihtuTaakse = function()
    local soihtuSlot = utils.etsiRepusta("minecraft:torch")
    if soihtuSlot then
        turtle.select(soihtuSlot)
        tracker:turnAround()
        turtle.place()
        tracker:turnAround()
        print("Soihtu asetettu taakse.")
    else
        print("Ei soihtua repussa!")
        --- lopeta ohjelma
        error("Ei soihtua repussa!") 
    end
end

-- Pääsilmukka: kaiva tunnelia eteenpäin
while true do
    tracker:cycle(function()
        -- kaiva 4 kertaa
        for i = 1, 4 do
            kaiva(false)
            tracker:digUp()
            tracker:forward()
        end
        -- mene ylös
        tracker:digUp()
        tracker:up()
        tracker:turnLeft()

        for i = 1, 5 do
            kaiva(false)
            tracker:forward()
        end
        tracker:turnAround()
        for i = 1, 5 do
            tracker:forward()
        end
        for i = 1, 5 do
            kaiva(false)
            tracker:forward()
        end
        tracker:turnAround()
        for i = 1, 5 do
            tracker:forward()
        end
        -- oikealle
        tracker:turnRight()
        -- mene alas
        tracker:down()
        tracker:forward()
        laitaSoihtuTaakse()
    end)
end