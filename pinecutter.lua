
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
tracker = Actions.new("pinecutter")

local PINE_LOG_BLOCK = "minecraft:pine_log"
local PINE_SAPLING_ITEM = "minecraft:pine_sapling"
local LEAVES_BLOCK = "minecraft:pine_leaves"

-- Hakkaa ylös kunnes ei mitään blokkeja
local function hakkaaYlos()
  while true do
    local success, data = turtle.inspectUp()
    if success and (data.name == PINE_LOG_BLOCK or data.name == LEAVES_BLOCK) then
      tracker:digUp()
      tracker:up()
    else
      break
    end
  end
end

-- Hakkaa alas kunnes ei enää leaves tai log alapuolella
local function hakkaaAlas()
  while true do
    local success, data = turtle.inspectDown()
    if success and (data.name == PINE_LOG_BLOCK or data.name == LEAVES_BLOCK) then
      tracker:digDown()
      tracker:down()
    else
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
    tracker:turnRight()
  end
end

hakkaaKuusi()

-- -- Pääsilmukka
-- while true do
--   tracker:cycle(function()
    
--   end)
-- end
