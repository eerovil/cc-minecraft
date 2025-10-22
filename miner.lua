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
    local successUp, dataUp = turtle:inspectUp()
    if successUp and dataUp.name == "minecraft:torch" then
        print("Soihtu yläpuolella, jätetään se rauhaan.")
        return
    end
    tracker:digUp()
end

local laitaSoihtu = function() 
    local soihtuSlot = utils.etsiRepusta("minecraft:torch")
    if soihtuSlot then
        turtle.select(soihtuSlot)
        turtle.digUp()
        turtle.placeUp()
        print("Soihtu asetettu alas.")
    else
        print("Ei soihtua repussa!")
        --- lopeta ohjelma
        error("Ei soihtua repussa!") 
    end
end

-- Pääsilmukka: kaiva tunnelia eteenpäin
while true do
    tracker:cycle(function()
        laitaSoihtu()
        -- kaiva 10 kertaa
        for i = 1, 10 do
            kaiva(false)
            tracker:forward()
        end
        laitaSoihtu()
        -- käänny oikealle
        tracker:turnRight()
        -- kaiva 4 kertaa
        for i = 1, 4 do
            kaiva(false)
            tracker:forward()
        end
        laitaSoihtu()
        -- käänny oikealle
        tracker:turnRight()
        -- kaiva 10 kertaa
        for i = 1, 10 do
            kaiva(false)
            tracker:forward()
        end
        laitaSoihtu()
        -- käänny vasemmalle
        tracker:turnLeft()
        -- kaiva 4 kertaa
        for i = 1, 4 do
            kaiva(false)
            tracker:forward()
        end
        -- käänny vasemmalle
        tracker:turnLeft()
        -- valmis!
    end)
end