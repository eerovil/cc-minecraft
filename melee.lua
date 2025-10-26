local utils = dofile("lib/utils.lua")

local function selectSlotWithAnyItem()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
      turtle.select(slot)
      return true
    end
  end
  return false
end

while true do
    for i = 1, 8 do
        turtle.attack()
        turtle.turnRight()
    end
    turtle.back()
    turtle.attack()
    turtle.forward()
    turtle.dropDown()
    selectSlotWithAnyItem()
end