-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")


local PITUUS=10

-- Pääsilmukka: kaiva 2 korkuista tunnelia x blokkia, sitten käänny 180 astetta ja toista
while true do
    tracker = Actions.new("hallikaivaja")
    tracker:cycle(function()
        -- aloita "uusi" seinän poisto
        turtle.dig()
        turtle.digUp()
        tracker:moveForward()
        tracker:turnRight()
        -- kaiva 10 eteenpäin ja ylös
        for i = 1, (PITUUS - 1) do
            turtle.dig()
            turtle.digUp()
            tracker:moveForward()
        end
        -- käänny oikealle
        tracker:turnLeft()
        turtle.dig()
        turtle.digUp()
        tracker:moveForward()
        tracker:turnLeft()
        -- kaiva 10 eteenpäin ja ylös
        for i = 1, (PITUUS - 1) do
            turtle.dig()
            turtle.digUp()
            tracker:moveForward()
        end
        tracker:turnRight()
    end)
end
