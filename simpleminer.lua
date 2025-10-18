-- Kaivaa kahden blokin korkuista tunnelia eteenpäin

local function safeForward()
  while not turtle.forward() do
    turtle.dig()
    sleep(0.2)
  end
end


local function refuel()
    local goodFuel = {"minecraft:coal", "minecraft:charcoal"}
    -- jos polttoainetta on alle 500, yritä tankata
    if turtle.getFuelLevel() < 500 then
        print("Polttoainetta vähän, yritetään tankata...")
        for slot = 1, 16 do
            turtle.select(slot)
            local itemCount = turtle.getItemCount(slot)
            if itemCount > 0 then
                local itemDetail = turtle.getItemDetail(slot)
                if itemDetail.name == goodFuel[1] or itemDetail.name == goodFuel[2] then
                    turtle.refuel()
                    print("Tankattu " .. itemCount .. " kappaletta " .. itemDetail.name)
                    if turtle.getFuelLevel() >= 1000 then
                        print("Polttoaine riittää nyt.")
                        return
                    end
                end
            end
        end
        print("Ei löytynyt polttoainetta tankattavaksi.")
    end
end


-- Pääsilmukka: kaiva tunneli eteenpäin 5 blokkia (2 korkuinen)
-- sitten käänny suuntaan jossa on blokkeja. Jatka siitä
while true do
    refuel()
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
