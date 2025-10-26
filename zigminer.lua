-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")
tracker = Actions.new(utils.getLabel())


local SPIRAL_SIDE = 5
local currLen = SPIRAL_SIDE

-- jos argsista löytyy tallennettu tila, lataa se
local args = {...}
if args[1] then 
    -- force save new state
    utils.saveState({currLen=args[1]})
end

local savedState = utils.loadState()
if savedState then
    currLen = savedState.currLen or SPIRAL_SIDE
end


local interestingBlocks = {
    "minecraft:diamond_ore",
    "minecraft:deepslate_diamond_ore",
    "minecraft:gold_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:emerald_ore",
    "minecraft:deepslate_emerald_ore",
    "minecraft:iron_ore",
    "minecraft:deepslate_iron_ore",
    "minecraft:coal_ore",
    "minecraft:deepslate_coal_ore",
    "minecraft:redstone_ore",
    "minecraft:deepslate_redstone_ore",
    "minecraft:lapis_ore",
    "minecraft:deepslate_lapis_ore",
}
local blockIsInteresting = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
}
local badItemNames = {
    "gravel",
    "dirt",
    "flint",
    "copper",
    "diorite",
    "andesite",
    "stone",
}

function pudotaJotainJosReppuFull()
    local emptySlots = 0
    local itemsBySlot = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            itemsBySlot[slot] = item
        else
            emptySlots = emptySlots + 1
        end
    end
    if emptySlots < 2 then
        print("Reppu täynnä, pudotetaan jotain...")
        -- pudota jotain ylimääräistä, esim. kiviblokkeja
        for _, badName in ipairs(badItemNames) do
            for slot, item in pairs(itemsBySlot) do
                if string.find(item.name, badName) then
                    turtle.select(slot)
                    turtle.dropDown(item.count)
                    print("Pudotettu "..item.count.." "..badName.." alaspäin.")
                    return
                end
            end
        end
        print("Ei löytynyt pudotettavaa.")
    end
end

local kaivaSuoni = function()
    pudotaJotainJosReppuFull()
    local suoniKaivaja = SuoniKaivaja.new(tracker, interestingBlocks)
    suoniKaivaja:aloita()
end

local nopeaTsekkaus = function(suunnat)
    -- katso ylös, alas ja eteenpäin, palauta true jos mielenkiintoinen blokki löytyy
    for _, dir in ipairs(suunnat) do
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


local function kaivaNBlokkia(n)
    for i = 1, n do
        if (nopeaTsekkaus({"up", "down"})) then
            kaivaSuoni()
        end
        tracker:dig()
        -- tracker:digUp()
        tracker:safeForward()
    end
    if (nopeaTsekkaus({"forward"})) then
        kaivaSuoni()
    end
end

function palaaAlkuun()
    tracker:moveTo(0, 0, 0)
    while tracker:facingName() ~= "north" do
        tracker:turnRight()
    end
end


-- Pääsilmukka: kaiva tunnelia eteenpäin
local stop = false
while true do
    if stop then
        break
    end
    tracker:cycle(function()
        if not (utils.refuel()) then
            print("Ei polttoainetta, palataan takaisin.")
            palaaAlkuun()
            stop = true
            return
        end
        kaivaNBlokkia(currLen)
        tracker:turnRight()
        pudotaJotainJosReppuFull()
        kaivaNBlokkia(currLen)
        tracker:turnRight()
        pudotaJotainJosReppuFull()
        currLen = currLen - 2
        utils.saveState({currLen=currLen})
        if currLen <= 0 then
            print("Kaivettu kaikki kerrokset")
            palaaAlkuun()
            stop = true
            return
        end
    end)
end

shell.run("resetstate.lua")
