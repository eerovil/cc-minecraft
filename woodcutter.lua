
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka
local utils = dofile("lib/utils.lua")


-- Hakkaa puu
-- Ensin hakkaa edessä oleva,
-- sitten mene suoraan
-- sitten alapuolella oleva
-- sitten toista: Hakkaa yläpuolella oleva ja mene ylös
-- kunnes ei ole enää puuta Sitten liiku alas (muista kuinka monta askelta ylös mentiin)
local function hakkaaPuu(kohdalla)
  if not kohdalla then
    -- Hakkaa edessä oleva puu
    turtle.dig()
    utils.safeForward()
  end
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

local suckUpAllAround = function()
  for i = 1, 4 do
    turtle.suck()
    turtle.turnRight()
  end
end


-- Pääsilmukka
while true do
  utils.safeForward()
  suckUpAllAround()
  utils.refuel()
  local ahead = utils.inspectAhead()
  if ahead and string.find(ahead, "log") then
    print("Edessä puu, hakataan se.")
    hakkaaPuu()
    istutaTaimi()
    sleep(0.5)
  end
  -- jos yllä on puu, hakkaa sekin
  local above = utils.inspectUp()
	local below = utils.inspectDown()
  if (above and string.find(above, "log")) or (below and string.find(below, "log")) then
    print("Yllä/Alla puu, hakataan se.")
    hakkaaPuu(true)
    istutaTaimi()
    sleep(0.5)
  end

	below = utils.inspectDown()
	if below and string.find(below, "sapling") then
    print("Alapuolella taimi, mennään eteenpäin.")
	else
		print("Ei saplingia alapuolella, käännytään.")
		utils.turnAround()
		sleep(60)
	end
end
