
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


local function safeForward()
    refuel()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
    end
end


-- Tarkista alapuolinen blokki
local function inspectDown()
	local success, data = turtle.inspectDown()
	if success then
		print("Alapuolella: " .. (data.name))
		return data.name
	end
	print("Ei blokkia alapuolella.")
	return nil
end

-- Tarkista edessä oleva blokki
local function inspectAhead()
  local success, data = turtle.inspect()
  if success then
    print("Edessä: " .. (data.name))
    return data.name
  end
  print("Ei blokkia edessä.")
  return nil
end
