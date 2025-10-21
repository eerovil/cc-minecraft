-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")

-- Pääsilmukka: kaiva tunneli eteenpäin 3 blokkia (2 korkuinen)
-- sitten tee molempiin suuntiin yläreunassa 3 blokkia syvät kaivuut
-- joista näkee
while true do
    utils.refuel()
    for i = 1, 3 do
        -- Kaiva edessä
        turtle.dig()
        -- Mene eteenpäin
        utils.safeForward()
        -- Kaiva yläpuolella
        turtle.digUp()
    end

    turtle.up()
    -- kaiva oikea yläkaivuu
    turtle.turnRight()
    turtle.dig()
    utils.safeForward()
    turtle.dig()
    utils.safeForward()
    turtle.dig()
    utils.safeForward()
    turtle.back()
    turtle.back()
    turtle.back()
    turtle.turnLeft()
    -- kaiva vasen yläkaivuu
    turtle.turnLeft()
    turtle.dig()
    utils.safeForward()
    turtle.dig()
    utils.safeForward()
    turtle.dig()
    utils.safeForward()
    turtle.back()
    turtle.back()
    turtle.back()
    turtle.turnRight()

    turtle.down()
end
