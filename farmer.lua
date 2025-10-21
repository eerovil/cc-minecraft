
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka
local utils = dofile("lib/utils.lua")

-- tyhjennä reppu alapuolella olevaan säiliöön
local function emptyInventory()
    print("Tyhjennetään reppu...")
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.drop()
    end
    print("Reppu tyhjennetty.")
end

-- istuta taimi alapuolelle
local function istutaTaimi()
  -- Etsi taimi inventaariosta
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and string.find(item.name, "sapling") then
      turtle.select(slot)
      turtle.placeDown()
      print("Istutettu taimi alapuolelle.")
      return
    end
  end
  print("Ei tainta inventaariossa!")
end

local MAX_AGE = {
  ["minecraft:wheat"] = 7,
  ["minecraft:carrots"] = 7,
  ["minecraft:potatoes"] = 7,
  ["minecraft:beetroots"] = 3
}

local function kasviAlapuolella()
    local blockBelow = utils.inspectDown()
    if blockBelow == nil then
        return nil
    end
    local blockName = blockBelow.name
    if blockName == "minecraft:wheat" or
       blockName == "minecraft:beetroots" or
       blockName == "minecraft:carrots" or
       blockName == "minecraft:potatoes" then
        return blockBelow
    end
    return "reuna"
end


local function farmaa()
    refuel()
    local blockBelow = kasviAlapuolella()
    local blockAhead = utils.inspectAhead()
    -- onko alapuolella oleva vehnää, punajuurta, porkkanaa tai perunoita
    -- jos alapuolella on arkku, laita reppu tyhjäksi
    if blockAhead and blockAhead.name == "minecraft:chest" then
        emptyInventory()
        -- false niin kääntyy
        return false, false
    end
    if blockBelow and blockBelow ~= "reuna" then
        -- tarkista kasvu taso
        local age = (blockBelow.state and blockBelow.state.age) or 0
        if age == MAX_AGE[blockBelow.name] then
            print("Kasvi on valmis, korjataan...")
            turtle.digDown()
            return true, blockBelow.name
        end
        -- jatka farmausta
        return true, blockBelow.name
    else
        -- jos alapuolella on tyhjä, jatka farmausta
        if blockBelow == nil then
            return true, "tuntematon"
        end
    end
    print("Alapuolella ei ole farmauskasvia.")
    return false, false
end

local function etsiRepusta(nimi)
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == nimi then
            return slot
        end
    end
    return nil
end

local function istutaSiemen(nimi)
    if not nimi then
        print("Ei tiedetä mitä istuttaa.")
        return false
    end
    local siemenet = {
        ["minecraft:wheat"]     = "minecraft:wheat_seeds",
        ["minecraft:beetroots"] = "minecraft:beetroot_seeds",
        ["minecraft:carrots"]   = "minecraft:carrot",
        ["minecraft:potatoes"]  = "minecraft:potato",
    }
    local siemenNimi = siemenet[nimi]
    if siemenNimi then
        -- etsi siemen inventaariosta
        local slot = etsiRepusta(siemenNimi)
        if not slot then
            print("Ei löytynyt siementä: " .. siemenNimi)
            return
        end
        turtle.select(slot)
        local onnistui = turtle.placeDown()
        if not onnistui then
            print("Ei voitu istuttaa siementä: " .. siemenNimi)
            return
        end
        print("Istutettu " .. siemenNimi .. " alapuolelle.")
        return true
    else
        print("Tuntematon siemen: " .. nimi)
    end
end

-- Pääsilmukka
--liiku eteenpäin ja suorita farmaus
local viimeisinKasvi = nil
local edellinenSuunta = "vasen"
local state = M.loadState() or {}
if state.edellinenSuunta then
    edellinenSuunta = state.edellinenSuunta
end

local asetaEdellinenSuunta = function(suunta)
    edellinenSuunta = suunta
    state.edellinenSuunta = suunta
    M.saveState(state)
end

while true do
    utils.refuel()
    local farmausOnnistui, farmattuKasvi = farmaa()
    if farmattuKasvi and farmattuKasvi ~= "tuntematon" then
        viimeisinKasvi = farmattuKasvi
    end
    if farmausOnnistui then
        istutusOnnistui = istutaSiemen(viimeisinKasvi)
        utils.safeForward()
    else
        if edellinenSuunta == "vasen" then
            -- Olemme reunan päällä, pitää kääntyä oikealle.
            -- mene taaksepäin, käänny oikealle, mene eteenpäin, käänny oikealle
            turtle.back()
            turtle.turnRight()
            utils.safeForward()
            turtle.turnRight()
            asetaEdellinenSuunta("oikea")
        else
            -- Olemme reunan päällä, pitää kääntyä vasemmalle.
            -- mene taaksepäin, käänny vasemmalle, mene eteenpäin, käänny vasemmalle
            turtle.back()
            turtle.turnLeft()
            utils.safeForward()
            turtle.turnLeft()
            asetaEdellinenSuunta("vasen")
        end
        viimeisinKasvi = nil
        local blockBelow = kasviAlapuolella()
        -- jos alapuolella on reuna vieläkin, meidän pitää mennä takaisin
        if blockBelow == "reuna" then
            print("Alapuolella ei ole farmauskasvia, käännytään uudestaan.")
            if edellinenSuunta == "vasen" then
                turtle.turnLeft()
                utils.safeForward()
                turtle.turnRight()
                asetaEdellinenSuunta("oikea")
            else
                turtle.turnRight()
                utils.safeForward()
                turtle.turnLeft()
                asetaEdellinenSuunta("vasen")
            end
        end
    end
end
