
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")

tracker = Actions.new(utils.getLabel())

local SPRUCE_LOG_BLOCK = "minecraft:spruce_log"
local SPRUCE_SAPLING_ITEM = "minecraft:spruce_sapling"
local LEAVES_BLOCK = "minecraft:spruce_leaves"

local function riittavastiSaplingeja()
  local totalSaplings = 0
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == SPRUCE_SAPLING_ITEM then
      totalSaplings = totalSaplings + item.count
    end
  end
  return totalSaplings >= 8
end

-- Hakkaa ylös kunnes ei mitään blokkeja
local function hakkaaYlos()
  while true do
    utils.refuel()
    local success, data = tracker:inspect()
    -- jos edessä on lehti, hakkaa se pois
    if success and data.name == LEAVES_BLOCK then
      -- hakkaa suoni lehtiä
      local suoniKaivaja = SuoniKaivaja.new(tracker, {LEAVES_BLOCK}, riittavastiSaplingeja)
      suoniKaivaja:aloita()
    end

    local success, data = tracker:inspectUp()
    if success and (data.name == SPRUCE_LOG_BLOCK or data.name == LEAVES_BLOCK) then
      tracker:digUp()
      tracker:safeUp()
    else
      print("yläpuolella: " .. (data and data.name or "ei mitään"))
      tracker:digUp()
      tracker:safeUp()
      tracker:digUp()
      tracker:safeUp()
      break
    end
  end
end

-- Hakkaa alas kunnes ei enää leaves tai log alapuolella
local function hakkaaAlas()
  tracker:digDown()
  tracker:safeDown()
  tracker:digDown()
  tracker:safeDown()
  while true do
    utils.refuel()
    local success, data = tracker:inspect()
    -- jos edessä on lehti, hakkaa se pois
    if success and data.name == LEAVES_BLOCK then
      -- hakkaa suoni lehtiä
      local suoniKaivaja = SuoniKaivaja.new(tracker, {LEAVES_BLOCK}, riittavastiSaplingeja)
      suoniKaivaja:aloita()
    end

    local success, data = tracker:inspectDown()
    if success and (data.name == SPRUCE_LOG_BLOCK or data.name == LEAVES_BLOCK) then
      tracker:digDown()
      tracker:safeDown()
    else
      print("alapuolella: " .. (data and data.name or "ei mitään"))
      break
    end
  end
end

-- Hakkaa puu
local function hakkaaKuusi()
  tracker:dig()
  tracker:safeForward()
  hakkaaYlos()
  tracker:dig()
  tracker:safeForward()
  hakkaaAlas()
  tracker:turnLeft()
  tracker:dig()
  tracker:safeForward()
  tracker:turnLeft()
  hakkaaYlos()
  tracker:dig()
  tracker:safeForward()
  hakkaaAlas()
  tracker:turnLeft()
  tracker:safeForward()
  tracker:turnLeft()
  tracker:safeBack()
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

-- istuta kuusi edessä
local function istutaKuusi()
  tracker:safeForward()
  tracker:safeUp()
  istutaTaimi()
  tracker:safeForward()
  istutaTaimi()
  tracker:turnLeft()
  tracker:safeForward()
  istutaTaimi()
  tracker:turnLeft()
  tracker:safeForward()
  istutaTaimi()
  tracker:turnLeft()
  tracker:safeForward()
  tracker:turnLeft()
  tracker:back()
  tracker:safeDown()
end


local suckUpAllAround = function()
  for i = 1, 4 do
    turtle.suck()
    tracker:turnRight()
  end
end

while true do
  tracker:cycle(function() 
    if not (utils.refuel()) then
      error("Ei riittävästi polttoainetta!")
    end
    suckUpAllAround()

    -- liiku eteenpäin 1
    tracker:safeForward()
    ok, data = tracker:inspect()
    -- onko kasvanut?
    if (ok and data.name == SPRUCE_LOG_BLOCK) then
      hakkaaKuusi()
      istutaKuusi()
    end
    suckUpAllAround()
    -- liiku taaksepäin 1
    tracker:back()
    -- odota 2 sekuntia ennen seuraavaa tarkistusta
    os.sleep(2)
    -- käänny 180 astetta
    tracker:turnRight()
  end)
end

-- -- Pääsilmukka
-- while true do
--   tracker:cycle(function()
    
--   end)
-- end
