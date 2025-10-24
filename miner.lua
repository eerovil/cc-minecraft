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


local kaiva = function(eitsekkaa)
    utils.refuel()
    local suoniKaivaja = SuoniKaivaja.new(tracker, interestingBlocks)
    suoniKaivaja:aloita()
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
        return true
    else
        print("Ei soihtua repussa!")
        --- lopeta ohjelma
        return false
    end
    return false
end

function asetaBlokkiAlas()
    -- jos alapuolella on tyhjä, laita jokin blokki
    local successDown, dataDown = turtle.inspectDown()
    if not successDown then
        -- etsi jokin blokki, nimessä "stone" repusta
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot)
            if item and string.find(item.name, "stone") then
                turtle.select(slot)
                turtle.placeDown()
                print("Asetettu blokki alapuolelle.")
                return
            end
        end
        print("Ei stone-blokkia inventaariossa!")
    end
end

function meneTakaisin()
    print("Mene takaisin lähtöpisteeseen.")
    tracker:safeUp()
    -- jos takana on blokki, pysähdy
    while true do
        local successBack, dataBack = turtle.inspect()
        if successBack then
            tracker:safeDown()
            return
        end
        tracker:safeBack()
    end
end

-- Pääsilmukka: kaiva tunnelia eteenpäin
stop = false
while true do
    if stop then
        break
    end
    tracker:cycle(function()
        if not (laitaSoihtuTaakse()) then
            print("Ei voi laittaa soihtua taakse, palataan takaisin.")
            meneTakaisin()
            stop = true
            return
        end
        -- kaiva 3 kertaa
        for i = 1, 3 do
            asetaBlokkiAlas()
            kaiva(false)
            tracker:digUp()
            tracker:safeForward()
        end
        -- mene ylös
        tracker:digUp()
        tracker:safeUp()
        tracker:turnLeft()

        for i = 1, 5 do
            kaiva(false)
            tracker:safeForward()
        end
        tracker:turnAround()
        for i = 1, 5 do
            tracker:safeForward()
        end
        for i = 1, 5 do
            kaiva(false)
            tracker:safeForward()
        end
        tracker:turnAround()
        for i = 1, 5 do
            tracker:safeForward()
        end
        -- oikealle
        tracker:turnRight()
        -- mene alas
        tracker:safeDown()
        kaiva(false)
        asetaBlokkiAlas()
        tracker:safeForward()
        if not (utils.refuel()) then
            print("Ei polttoainetta, palataan takaisin.")
            meneTakaisin()
            stop = true
            return
        end
    end)
end