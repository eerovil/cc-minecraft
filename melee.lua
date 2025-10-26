local utils = dofile("lib/utils.lua")

while true do
    for i = 1, 8 do
        turtle.attack()
        turtle.turnRight()
    end
    turtle.back()
    turtle.attack()
    turtle.forward()
end