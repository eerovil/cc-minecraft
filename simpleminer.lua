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


-- Pääsilmukka: kaiva tunneli eteenpäin 3 blokkia (2 korkuinen)
-- sitten tee molempiin suuntiin yläreunassa 3 blokkia syvät kaivuut
-- joista näkee
while true do
    refuel()
    for i = 1, 3 do
        -- Kaiva edessä
        turtle.dig()
        -- Mene eteenpäin
        safeForward()
        -- Kaiva yläpuolella
        turtle.digUp()
    end

    turtle.up()
    -- kaiva oikea yläkaivuu
    turtle.turnRight()
    turtle.dig()
    safeForward()
    turtle.dig()
    safeForward()
    turtle.dig()
    safeForward()
    turtle.back()
    turtle.back()
    turtle.back()
    turtle.turnLeft()
    -- kaiva vasen yläkaivuu
    turtle.turnLeft()
    turtle.dig()
    safeForward()
    turtle.dig()
    safeForward()
    turtle.dig()
    safeForward()
    turtle.back()
    turtle.back()
    turtle.back()
    turtle.turnRight()

    turtle.down()
end
