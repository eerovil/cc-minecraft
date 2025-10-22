-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")

-- args on leveys ja sitten korkeus ja sitten syvyys
local args = {...}
local leveys = tonumber(args[1]) or 2
local korkeus = tonumber(args[2]) or 2
local syvyys = tonumber(args[3]) or 100

if args[1] then 
    -- force save new state
    utils.saveState({width=leveys, height=korkeus, depth=syvyys})
end

local savedState = utils.loadState()
if savedState then
    -- aseta leveys, korkeus, syvyys tallennetusta tilasta
    leveys = savedState.width or leveys
    korkeus = savedState.height or korkeus
    syvyys = savedState.depth or syvyys
end

print("Asetettu leveys: " .. leveys .. ", korkeus: " .. korkeus .. ", syvyys: " .. syvyys)
-- hae 

utils.saveState({width=leveys, height=korkeus, depth=syvyys})

local function kaivaKorkeutta(tracker)
    -- jos korkeus on 1, älä tee mitään
    if korkeus <= 1 then
        return
    end
    if korkeus == 2 then
        tracker:digUp()
        return
    end
    -- yli 2 on hankalampi.
    for i = 1, korkeus - 2 do
        tracker:digUp()
        tracker:moveUp()
    end
    tracker:digUp()
    for i = 1, korkeus - 2 do
        tracker:moveDown()
    end
end


-- Pääsilmukka: kaiva 2 korkuista tunnelia x blokkia, sitten käänny 180 astetta ja toista
while true do
    tracker = Actions.new("hallikaivaja")
    tracker:cycle(function()
        -- aloita "uusi" seinän poisto
        turtle.dig()
        tracker:moveForward()
        kaivaKorkeutta(tracker)
        tracker:turnRight()
        -- kaiva 10 eteenpäin ja ylös
        for i = 1, (leveys - 1) do
            utils.refuel()
            turtle.dig()
            tracker:moveForward()
            kaivaKorkeutta(tracker)
        end
        -- käänny oikealle
        tracker:turnLeft()
        turtle.dig()
        tracker:moveForward()
        kaivaKorkeutta(tracker)
        tracker:turnLeft()
        -- kaiva 10 eteenpäin ja ylös
        for i = 1, (leveys - 1) do
            utils.refuel()
            turtle.dig()
            tracker:moveForward()
            kaivaKorkeutta(tracker)
        end
        tracker:turnRight()
    end)
    -- vähennä syvyyttä 2
    syvyys = syvyys - 2
    if syvyys <= 0 then
        print("Kaivettu vaadittu syvyys, lopetetaan.")
        break
    end
    -- tallenna tila
    utils.saveState({width=leveys, height=korkeus, depth=syvyys})
    print("Jäljellä syvyyttä: " .. syvyys)
    utils.refuel()
end
