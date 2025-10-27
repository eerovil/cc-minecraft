
-- Liiku eteenpäin kunnes alapuolella ei ole sapling-blokkia, sitten käänny 180 astetta ja jatka
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")
local SuoniKaivaja = dofile("lib/ore.lua")

tracker = Actions.new(utils.getLabel())

local SPRUCE_LOG_BLOCK = "minecraft:spruce_log"
local SPRUCE_SAPLING_ITEM = "minecraft:spruce_sapling"
local LEAVES_BLOCK = "minecraft:spruce_leaves"
local GROUND_BLOCK = "minecraft:podzol"
local DIRT_BLOCK = "minecraft:dirt"
local GRASS_BLOCK = "minecraft:grass_block"

local function saplingMaara()
  local totalSaplings = 0
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == SPRUCE_SAPLING_ITEM then
      totalSaplings = totalSaplings + item.count
    end
  end
  return totalSaplings
end

local function riittavastiSaplingeja()
  return saplingMaara() >= 8
end


-- Hakkaa ylös kunnes ei mitään blokkeja
local function hakkaaYlos()
  while true do
    utils.refuel()
    -- jos edessä on lehti, hakkaa se pois
    if tracker:inspectBlockIsOneOf("forward", {LEAVES_BLOCK}) then
      -- hakkaa suoni lehtiä
      local suoniKaivaja = SuoniKaivaja.new(tracker, {LEAVES_BLOCK}, riittavastiSaplingeja)
      suoniKaivaja:aloita()
    end

    if tracker:inspectBlockIsOneOf("up", {SPRUCE_LOG_BLOCK, LEAVES_BLOCK}) then
      tracker:digUp()
      tracker:safeUp()
    else
      tracker:digUp()
      tracker:safeUp()
      tracker:digUp()
      tracker:safeUp()
      local success, data = tracker:inspectUp()
      if success then
        print("yläpuolella edelleen: ")
      else
        print("yläpuolella ei enää blokkeja.")
        break
      end
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
    -- jos edessä on lehti, hakkaa se pois
    if tracker:inspectBlockIsOneOf("forward", {LEAVES_BLOCK}) then
      -- hakkaa suoni lehtiä
      local suoniKaivaja = SuoniKaivaja.new(tracker, {LEAVES_BLOCK}, riittavastiSaplingeja)
      suoniKaivaja:aloita()
    end

    if tracker:inspectBlockIsOneOf("down", {GROUND_BLOCK, DIRT_BLOCK, GRASS_BLOCK}) then
      break
    else
      tracker:digDown()
      tracker:safeDown()
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
local function istutaTaimiEteen()
  -- Etsi taimi inventaariosta
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and string.find(item.name, "sapling") then
      turtle.select(slot)
      turtle.place()
      print("Istutettu taimi eteen.")
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

local etsiMaa = function()
  -- mene alas kunnes y == 0
  tracker:moveTo(0, 0, 0)
end

local laitaArkkuun = function()
  -- arkku pitäisi olla nyt alapuolella
  -- ota sieltä hiiltä ja saplingeja
  -- laita kaikki puut arkkuun

  -- inspectaa arkku
  if tracker:inspectBlockIsOneOf("down", {"minecraft:chest"}) then
    print("Löydettiin arkku: ")
  else
    print("Ei arkku löytynyt.")
  end

  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item then
      if string.find(item.name, "log") or string.find(item.name, "planks") or string.find(item.name, "stick") then
        turtle.select(slot)
        turtle.dropDown()
        print("Laitettu arkkuun: " .. item.name .. " x" .. item.count)
      end
    end
  end
end

local varmistaEdessaOnTaimiTaiKuusi = function()
  if tracker:inspectBlockIsOneOf("forward", {SPRUCE_LOG_BLOCK, SPRUCE_SAPLING_ITEM}) then
    return true
  else
    -- rikoita edessä oleva blockki
    tracker:dig()
    -- istuta taimi
    istutaTaimiEteen()
  end
end

local function keraile()
  local taimia = false
  local kuusia = false
  -- käy edessä olevan taimen ympärillä ja kerää kaikki esineet
  tracker:safeForward()
  varmistaEdessaOnTaimiTaiKuusi()
  tracker:turnLeft()
  tracker:safeForward()
  tracker:safeForward()
  suckUpAllAround()
  tracker:turnRight()
  tracker:safeForward()

  tracker:turnRight()
  varmistaEdessaOnTaimiTaiKuusi()
  tracker:turnLeft()

  tracker:safeForward()
  suckUpAllAround()
  tracker:safeForward()
  tracker:turnRight()
  tracker:safeForward()

  tracker:turnRight()
  varmistaEdessaOnTaimiTaiKuusi()
  tracker:turnLeft()

  tracker:safeForward()
  suckUpAllAround()
  tracker:safeForward()
  tracker:turnRight()
  tracker:safeForward()

  tracker:turnRight()
  varmistaEdessaOnTaimiTaiKuusi()
  tracker:turnLeft()

  tracker:safeForward()
  suckUpAllAround()
  tracker:safeForward()
  tracker:turnRight()
  tracker:safeForward()
  tracker:turnLeft()
  tracker:safeForward()
  tracker:turnAround()
end

local stop = false
while true do
  if stop then break end
  tracker:cycle(function() 
    if not (utils.refuel()) then
      error("Ei riittävästi polttoainetta!")
    end
    etsiMaa()
    -- jos ei ole arkkua alla, niin error
    if not tracker:inspectBlockIsOneOf("down", {"minecraft:chest"}) then
    error("Ei arkkua alla!")
    end
    laitaArkkuun()
    suckUpAllAround()

    -- liiku eteenpäin 1
    tracker:safeForward()
    if tracker:inspectBlockIsOneOf("forward", {SPRUCE_LOG_BLOCK}) then
      hakkaaKuusi()
    end
    suckUpAllAround()
    -- liiku taaksepäin 1
    tracker:safeBack()
    -- käänny 180 astetta
    tracker:turnRight()
    -- stop = true
    keraile()
  end)
end

-- -- Pääsilmukka
-- while true do
--   tracker:cycle(function()
    
--   end)
-- end
