-- Kaivaa kahden blokin korkuista tunnelia eteenpäin
local utils = dofile("lib/utils.lua")
local Actions = dofile("lib/actions.lua")

-- local function zigzagStep(step)
--     -- eteenpäin
--     turtle.dig()
--     utils.safeForward()
--     -- oikealle
--     turtle.turnRight()
--     turtle.dig()
--     utils.safeForward()
--     -- vasemmalle
--     turtle.turnLeft()
--     turtle.dig()
--     utils.safeForward()
--     -- vasemmalle
--     turtle.turnLeft()
--     turtle.dig()
--     utils.safeForward()
--     -- oikealle
--     turtle.turnRight()
-- end

-- Pääsilmukka: tee 3x3 neliö
while true do
    tracker = Actions.new("hallikaivaja")
    tracker:cycle(function()
        -- kaiva 3 eteenpäin
        for i = 1, 3 do
            turtle.dig()
            tracker:moveForward()
        end
        -- käänny oikealle
        tracker:turnRight()
        -- kaiva 3 eteenpäin
        for i = 1, 3 do
            turtle.dig()
            tracker:moveForward()
        end
        -- käänny oikealle
        tracker:turnRight()
        -- kaiva 3 eteenpäin
        for i = 1, 3 do
            turtle.dig()
            tracker:moveForward()
        end
        -- käänny oikealle
        tracker:turnRight()
        -- kaiva 3 eteenpäin
        for i = 1, 3 do
            turtle.dig()
            tracker:moveForward()
        end
        -- käänny alkuperäiseen suuntaan
        tracker:turnRight()
    end)
end
