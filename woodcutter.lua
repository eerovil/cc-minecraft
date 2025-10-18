
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


-- Pääsilmukka
while true do
	sleep(2)
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
		sleep(0.5)
	end
end
