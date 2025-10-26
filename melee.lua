local utils = dofile("lib/utils.lua")

local function dropAllItems()
  for slot = 1, 16 do
    turtle.select(slot)
    turtle.drop()
  end
end

while true do
    for i = 1, 8 do
        turtle.attack()
        turtle.turnRight()
    end
    turtle.back()
    turtle.attack()
    turtle.forward()
    dropAllItems()
end