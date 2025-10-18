-- Kaivaa kahden blokin korkuista tunnelia eteenpäin

local function safeForward()
  while not turtle.forward() do
    turtle.dig()
    sleep(0.2)
  end
end


-- Pääsilmukka: kaiva tunneli eteenpäin 5 blokkia (2 korkuinen)
-- sitten käänny suuntaan jossa on blokkeja. Jatka siitä
while true do
    for i = 1, 5 do
        -- Kaiva edessä
        turtle.dig()
        -- Mene eteenpäin
        safeForward()
        -- Kaiva yläpuolella
        turtle.digUp()
    end
    
    -- Etsi suunta jossa on blokkeja
    turtle.turnRight()
    local foundBlock = false
    for i = 1, 4 do
        local success, data = turtle.inspect()
        if success then
        print("Löydettiin blokki edessä: " .. (data.name or "tuntematon"))
        foundBlock = true
        break
        end
        turtle.turnRight()
    end
    
    if not foundBlock then
        print("Ei löydetty blokkeja ympäriltä, jatketaan.")
    end
end
