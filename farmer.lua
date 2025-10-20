
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka

-- Turvallinen eteenpäinliike
local function safeForward()
	while not turtle.forward() do
		print("Edessä este, yritetään kaivaa...")
		turtle.dig()
		sleep(0.2)
	end
	print("Liikuttiin eteenpäin.")
end

-- tyhjennä reppu alapuolella olevaan säiliöön
local function emptyInventory()
    print("Tyhjennetään reppu...")
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.drop()
    end
    print("Reppu tyhjennetty.")
end

-- Tarkista alapuolinen blokki
local function inspectDown()
	local success, data = turtle.inspectDown()
	if success then
		print("Alapuolella: " .. (data.name or "tuntematon"))
		return data
	end
	print("Ei blokkia alapuolella.")
	return nil
end

-- Tarkista edessä oleva blokki
local function inspectAhead()
  local success, data = turtle.inspect()
  if success then
    print("Edessä: " .. (data.name or "tuntematon"))
    return data
  end
  print("Ei blokkia edessä.")
  return nil
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

local MAX_AGE = {
  ["minecraft:wheat"] = 7,
  ["minecraft:carrots"] = 7,
  ["minecraft:potatoes"] = 7,
  ["minecraft:beetroots"] = 3
}

local function kasviAlapuolella()
    local blockBelow = inspectDown()
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
    local blockAhead = inspectAhead()
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
while true do
    local farmausOnnistui, farmattuKasvi = farmaa()
    if farmattuKasvi and farmattuKasvi ~= "tuntematon" then
        viimeisinKasvi = farmattuKasvi
    end
    if farmausOnnistui then
        istutusOnnistui = istutaSiemen(viimeisinKasvi)
        safeForward()
    else
        if edellinenSuunta == "vasen" then
            -- käänny, liiku eteenpäin ja käänny
            turtle.turnRight()
            safeForward()
            turtle.turnRight()
            safeForward()
            edellinenSuunta = "oikea"
        else
            -- käänny, liiku eteenpäin ja käänny
            turtle.turnLeft()
            safeForward()
            turtle.turnLeft()
            safeForward()
            edellinenSuunta = "vasen"
        end
        viimeisinKasvi = nil
        local blockBelow = kasviAlapuolella()
        -- jos alapuolella on tuntematon, meidän pitää kääntyä takaisin
        if blockBelow == "tuntematon" then
            print("Alapuolella ei ole farmauskasvia, käännytään uudestaan.")
            if edellinenSuunta == "vasen" then
                turtle.turnRight()
                turtle.turnRight()
                safeForward()
                turtle.turnRight()
                safeForward()
                turtle.turnRight()
                safeForward()
                edellinenSuunta = "oikea"
            else
                turtle.turnLeft()
                turtle.turnLeft()
                safeForward()
                turtle.turnLeft()
                safeForward()
                turtle.turnLeft()
                safeForward()
                edellinenSuunta = "vasen"
            end
        end
    end
end
