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

local SPIRAL_SIDE = 40

local currPos = {x=0, y=0, z=0}
local facing = "north"

local turnRightMap = {
    north = "east",
    east = "south",
    south = "west",
    west = "north",
}

local function turnRight()
    tracker:turnRight()
    facing = turnRightMap[facing]
end


local function kaivaNBlokkia(n)
    for i = 1, n do
        if (nopeaTsekkaus()) then
            kaivaSuoni()
        end
        tracker:dig()
        -- tracker:digUp()
        tracker:safeForward()
        if facing == "north" then
            currPos.x = currPos.x + 1
        elseif facing == "east" then
            currPos.z = currPos.z + 1
        elseif facing == "south" then
            currPos.x = currPos.x - 1
        elseif facing == "west" then
            currPos.z = currPos.z - 1
        end
    end
end

function palaaAlkuun()
    -- käänny kohti north
    if currPos.x > 0 then
        -- käänny etelään
        while facing ~= "south" do
            turnRight()
        end
        kaivaNBlokkia(currPos.x)
    elseif currPos.x < 0 then
        -- käänny pohjoiseen
        while facing ~= "north" do
            turnRight()
        end
        kaivaNBlokkia(-currPos.x)
    end
    if currPos.z > 0 then
        -- käänny länteen
        while facing ~= "west" do
            turnRight()
        end
        kaivaNBlokkia(currPos.z)
    elseif currPos.z < 0 then
        -- käänny itään
        while facing ~= "east" do
            turnRight()
        end
        kaivaNBlokkia(-currPos.z)
    end
    -- käänny pohjoiseen
    while facing ~= "north" do
        turnRight()
    end
end

-- Pääsilmukka: kaiva tunnelia eteenpäin
local currLen = SPIRAL_SIDE
kaivaNBlokkia(currLen)
turnRight()
while true do
    if not (utils.refuel()) then
        print("Ei polttoainetta, palataan takaisin.")
        palaaAlkuun()
        stop = true
        return
    end
    kaivaNBlokkia(currLen)
    turnRight()
    pudotaJotainJosReppuFull()
    kaivaNBlokkia(currLen)
    turnRight()
    pudotaJotainJosReppuFull()
    currLen = currLen - 2
    if currLen <= 0 then
        print("Kaivettu kaikki kerrokset")
        palaaAlkuun()
        break
    end
end

shell.run("resetstate.lua")
