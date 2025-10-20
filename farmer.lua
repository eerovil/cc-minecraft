
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


local function farmaa()
    refuel()
    local blockBelow = inspectDown()
    -- onko alapuolella oleva vehnää, punajuurta, porkkanaa tai perunoita
    if blockBelow.name == "minecraft:wheat" or
       blockBelow.name == "minecraft:beetroot" or
       blockBelow.name == "minecraft:carrots" or
       blockBelow.name == "minecraft:potatoes" then
        -- tarkista kasvu taso
        local nbt = blockBelow.state
        if nbt.age and nbt.age == 7 then
            print("Kasvi on valmis, korjataan...")
            turtle.digDown()
            return true, blockBelow.name
        end
        -- jatka farmausta
        return false, blockBelow.name
    else
        -- jos alapuolella on tyhjä, jatka farmausta
        if blockBelow == nil then
            return false, "tuntematon"
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
        "minecraft:wheat" = "minecraft:wheat_seeds",
        "minecraft:beetroot" = "minecraft:beetroot_seeds",
        "minecraft:carrot" = "minecraft:carrot",
        "minecraft:potatoe" = "minecraft:potato"
    }

    local siemenNimi = siemenet.minecraft[nimi]
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
while true do
    local farmausOnnistui, farmattuKasvi = farmaa()
    if farmattuKasvi and farmattuKasvi != "tuntematon" then
        viimeisinKasvi = farmausOnnistui
    end
    if farmausOnnistui then
        istutusOnnistui = istutaSiemen(viimeisinKasvi)
        if not istutusOnnistui then
            print("Lopetetaan, koska ei voida istuttaa.")
            break
        end
        safeForward()
    else
        -- käänny, liiku eteenpäin ja käänny
        turtle.turnRight()
        safeForward()
        turtle.turnRight()
        viimeisinKasvi = nil
    end
end
