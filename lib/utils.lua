local M = {}

function M.refuel()
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


function M.safeForward()
    while not turtle.forward() do
        turtle.dig()
        sleep(0.2)
    end
end

-- Tarkista yläpuolinen blokki
function M.inspectUp()
	local success, data = turtle.inspectUp()
	if success then
		print("Yllä: " .. (data.name))
		return data
	end
	print("Ei blokkia yllä.")
	return nil
end

-- Tarkista alapuolinen blokki
function M.inspectDown()
	local success, data = turtle.inspectDown()
	if success then
		print("Alapuolella: " .. (data.name))
		return data
	end
	print("Ei blokkia alapuolella.")
	return nil
end

-- Tarkista edessä oleva blokki
function M.inspectAhead()
  local success, data = turtle.inspect()
  if success then
    print("Edessä: " .. (data.name))
    return data
  end
  print("Ei blokkia edessä.")
  return nil
end

-- Käänny 180 astetta
function M.turnAround()
	turtle.turnRight()
	turtle.turnRight()
	print("Käännyttiin 180 astetta.")
end

local filename = "turtle_state.txt"

-- lataa tai tallenna state
function M.loadState()
    local file = fs.open(filename, "r")
    if file then
        local content = file.readAll()
        file.close()
        local state = textutils.unserialize(content)
        print("Ladattu tila tiedostosta " .. filename)
        return state
    else
        print("Ei löydetty tallennettua tilaa tiedostosta " .. filename)
        return nil
    end
end

-- tallenna tila tiedostoon
function M.saveState(state)
    local file = fs.open(filename, "w")
    if file then
        local content = textutils.serialize(state)
        file.write(content)
        file.close()
        print("Tallennettu tila tiedostoon " .. filename)
    else
        print("Ei voitu tallentaa tilaa tiedostoon " .. filename)
    end
end

return M