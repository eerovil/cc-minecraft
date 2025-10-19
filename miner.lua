-- Kaivaa kahden blokin korkuista tunnelia eteenpäin

local function refuel()
    local goodFuel = {"minecraft:coal", "minecraft:charcoal"}
    -- jos polttoainetta on alle 500, yritä tankata
    if turtle.getFuelLevel() < 500 then
        print("Polttoainetta vähän, yritetään tankata...")
        for slot = 1, 16 do
            turtle.select(slot)
            local itemCount = turtle.getItemCount(slot)
            if itemCount > 0 then
                local itemDetail = turtle.getItemDetail(slot)
                if itemDetail.name == goodFuel[1] or itemDetail.name == goodFuel[2] then
                    turtle.refuel()
                    print("Tankattu " .. itemCount .. " kappaletta " .. itemDetail.name)
                    if turtle.getFuelLevel() >= 1000 then
                        print("Polttoaine riittää nyt.")
                        return
                    end
                end
            end
        end
        print("Ei löytynyt polttoainetta tankattavaksi.")
    end
end

local function safeForward()
    refuel()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
    end
end


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
        turtle.digUp()
        turtle.up()
        inspectSurroundings()
        turtle.down()
    elseif direction == "down" then
        turtle.digDown()
        turtle.down()
        inspectSurroundings()
        turtle.up()
    elseif direction == "forward" then
        turtle.dig()
        safeForward()
        inspectSurroundings()
        turtle.back()
    end
end

inspectSurroundings = function()
    -- ensin katso ylös
    local successUp, dataUp = turtle.inspectUp()
    if successUp and isInterestingBlock(dataUp.name) then
        print("Yläpuolella: " .. (dataUp.name or "tuntematon"))
        kaivaSuoni("up")
    end
    -- sitten katso alas
    local successDown, dataDown = turtle.inspectDown()
    if successDown and isInterestingBlock(dataDown.name) then
        print("Alapuolella: " .. (dataDown.name or "tuntematon"))
        kaivaSuoni("down")
    end
    -- sitten katso eteen ja pyörähdä 3 kertaa
    for i = 1, 4 do
        local successAhead, dataAhead = turtle.inspect()
        if successAhead and isInterestingBlock(dataAhead.name) then
            print("Edessä: " .. (dataAhead.name or "tuntematon"))
            kaivaSuoni("forward")
        end
        turtle.turnRight()
    end
    print("Ei mielenkiintoista ympärillä.")
    return nil
end

local kaiva = function(eitsekkaa)
    -- ennen kaivamista, tarkista ympäristö
    if not eitsekkaa then
        inspectSurroundings()
    end
    turtle.dig()
end

-- Pääsilmukka: jatka tunnelin kaivamista
-- aluksi mene 3 blokkia eteenpäin kaivaten
local extrasilmukat = 5
local silmukanleveys = 3
local silmukanpituus = 20

local function drawSilmukka()
    -- ensin käänny vasemmalle
    turtle.turnLeft()
    -- sitten mene silmukanleveys eteenpäin
    for i = 1, silmukanleveys do
        kaiva()
        safeForward()
    end
    -- käänny oikealle
    turtle.turnRight()
    -- mene silmukanpituus eteenpäin
    for i = 1, silmukanpituus do
        kaiva()
        safeForward()
    end
    -- käänny oikealle
    turtle.turnRight()
    -- mene silmukanleveys taaksepäin
    for i = 1, silmukanleveys do
        kaiva()
        safeForward()
    end
    -- käänny oikealle
    turtle.turnRight()
    -- mene silmukanpituus taaksepäin
    for i = 1, silmukanpituus do
        kaiva()
        safeForward()
    end
    -- käänny alkuperäiseen suuntaan
    turtle.turnLeft()
    turtle.turnLeft()
end


--aluksi kaiva 3 eteenpäin
for i = 1, 3 do
    kaiva()
    safeForward()
end

drawSilmukka()

-- sitten piirrä silmukoita määrän verran
if extrasilmukat > 0 then
    for i = 1, extrasilmukat do
        --liiku oikealle 2 kertaa silmukan leveys ja käänny vasemmalle
        turtle.turnRight()
        for j = 1, silmukanleveys * 2 do
            kaiva()
            safeForward()
        end
        turtle.turnLeft()
        -- piirrä silmukka
        drawSilmukka()
    end
    turtle.turnLeft()
    -- liiku takaisin keskelle
    for j = 1, silmukanleveys * extrasilmukat * 2 do
        kaiva(true)
        safeForward()
    end
    turtle.turnRight()
end

print("Kaivettu kaikki silmukat.")
-- palaa alkuun

turtle.turnRight()
turtle.turnRight()

for i = 1, 3 do
    kaiva(true)
    safeForward()
end


turtle.turnRight()
turtle.turnRight()
print("Palattu alkuun.")
