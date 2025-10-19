
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
		return data.name
	end
	print("Ei blokkia alapuolella.")
	return nil
end

-- Tarkista edessä oleva blokki
local function inspectAhead()
  local success, data = turtle.inspect()
  if success then
    print("Edessä: " .. (data.name or "tuntematon"))
    return data.name
  end
  print("Ei blokkia edessä.")
  return nil
end

-- Käänny 180 astetta
local function turnAround()
	turtle.turnRight()
	turtle.turnRight()
	print("Käännyttiin 180 astetta.")
end


-- Hakkaa puu
-- Ensin hakkaa edessä oleva,
-- sitten mene suoraan
-- sitten alapuolella oleva
-- sitten toista: Hakkaa yläpuolella oleva ja mene ylös
-- kunnes ei ole enää puuta Sitten liiku alas (muista kuinka monta askelta ylös mentiin)
local function hakkaaPuu()
  -- Hakkaa edessä oleva puu
  turtle.dig()
  safeForward()
  -- Hakkaa alapuolella oleva puu
  turtle.digDown()
  local upCount = 0
  -- Hakkaa yläpuolella oleva puu ja mene ylös
  while true do
    local success, data = turtle.inspectUp()
    if success and string.find(data.name, "log") then
      turtle.digUp()
      turtle.up()
      upCount = upCount + 1
      print("Mennyt ylös, taso: " .. upCount)
    else
      break
    end
  end
  -- Liiku alas
  for i = 1, upCount do
    turtle.down()
  end
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

local suckUpAllAround = function()
  for i = 1, 4 do
    turtle.suck()
    turtle.turnRight()
  end
end


-- Pääsilmukka
while true do
  suckUpAllAround()
  refuel()
  local ahead = inspectAhead()
  if ahead and string.find(ahead, "log") then
    print("Edessä puu, hakataan se.")
    hakkaaPuu()
    istutaTaimi()
    sleep(0.5)
  end
	local below = inspectDown()
	if below and string.find(below, "sapling") then
		safeForward()
	else
		print("Ei saplingia alapuolella, käännytään.")
		turnAround()
    safeForward()
		sleep(60)
	end
end
