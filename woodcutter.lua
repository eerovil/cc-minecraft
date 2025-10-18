-- Move forward safely, digging if needed
local function safeForward()
  while not turtle.forward() do
    print("Blocked, digging ahead...")
    if not turtle.dig() then
      print("Can't dig in front! Maybe unbreakable block or no tool.")
      return false
    end
    sleep(0.2)
  end
  print("Moved forward.")
  return true
end

-- Move up safely, digging if needed
local function safeUp()
  while not turtle.up() do
    print("Blocked above, digging up...")
    if not turtle.digUp() then
      print("Can't dig up! Maybe unbreakable block or no tool.")
      return false
    end
    sleep(0.2)
  end
  print("Moved up.")
  return true
end

-- Move down safely, digging if needed
local function safeDown()
  while not turtle.down() do
    print("Blocked below, digging down...")
    if not turtle.digDown() then
      print("Can't dig down! Maybe unbreakable block or no tool.")
      return false
    end
    sleep(0.2)
  end
  print("Moved down.")
  return true
end

-- Turn right
local function turnRight()
  turtle.turnRight()
  print("Turned right.")
end

-- Turn left
local function turnLeft()
  turtle.turnLeft()
  print("Turned left.")
end

-- Inspect block in front
local function inspectFront()
  local success, data = turtle.inspect()
  if success then
    print("Inspected block: " .. (data.name or "unknown"))
    return data.name
  end
  print("No block in front.")
  return nil
end

-- Inspect block above
local function inspectUp()
  local success, data = turtle.inspectUp()
  if success then
    print("Inspected block above: " .. (data.name or "unknown"))
    return data.name
  end
  print("No block above.")
  return nil
end

-- Inspect block below
local function inspectDown()
  local success, data = turtle.inspectDown()
  if success then
    print("Inspected block below: " .. (data.name or "unknown"))
    return data.name
  end
  print("No block below.")
  return nil
end

-- Try to find wood in the 6 directions (front, up, down, left, right, back)
local function findWoodNearby()
  -- Check front, right, back, left
  for i = 1, 4 do
    local block = inspectFront()
    if block and string.find(block, "log") then
      print("Wood detected nearby (horizontal)!")
      return "front"
    end
    turnRight()
  end
  -- Check up
  local upBlock = inspectUp()
  if upBlock and string.find(upBlock, "log") then
    print("Wood detected above!")
    return "up"
  end
  -- Check down
  local downBlock = inspectDown()
  if downBlock and string.find(downBlock, "log") then
    print("Wood detected below!")
    return "down"
  end
  return false
end

-- Move to and cut wood in all directions (vertical and horizontal)
local function cutWood()
  while true do
    local dir = findWoodNearby()
    if dir == "front" then
      local block = inspectFront()
      print("Cutting wood in front: " .. block)
      local dug = false
      for attempt = 1, 5 do
        if turtle.dig() then
          dug = true
          break
        else
          print("Dig attempt " .. attempt .. " failed. Retrying...")
          sleep(0.2)
        end
      end
      if dug then
        safeForward()
      else
        print("Failed to dig front after multiple attempts! Block: " .. tostring(block))
        break
      end
    elseif dir == "up" then
      local block = inspectUp()
      print("Cutting wood above: " .. block)
      local dug = false
      for attempt = 1, 5 do
        if turtle.digUp() then
          dug = true
          break
        else
          print("DigUp attempt " .. attempt .. " failed. Retrying...")
          sleep(0.2)
        end
      end
      if dug then
        safeUp()
      else
        print("Failed to dig up after multiple attempts! Block: " .. tostring(block))
        break
      end
    elseif dir == "down" then
      local block = inspectDown()
      print("Cutting wood below: " .. block)
      local dug = false
      for attempt = 1, 5 do
        if turtle.digDown() then
          dug = true
          break
        else
          print("DigDown attempt " .. attempt .. " failed. Retrying...")
          sleep(0.2)
        end
      end
      if dug then
        safeDown()
      else
        print("Failed to dig down after multiple attempts! Block: " .. tostring(block))
        break
      end
    else
      print("No more wood in any direction.")
      break
    end
  end
end


-- Move the turtle to a specific position using BFS (relative to start, 3D)
local function moveTo(x, y, z)
  print("Moving to position (" .. x .. ", " .. y .. ", " .. (z or 0) .. ")")
  z = z or 0
  -- Move vertically first
  if z > 0 then for i = 1, z do safeUp() end end
  if z < 0 then for i = 1, -z do safeDown() end end
  -- Then move in x
  if x > 0 then for i = 1, x do turnRight(); safeForward(); turnLeft() end end
  if x < 0 then for i = 1, -x do turnLeft(); safeForward(); turnRight() end end
  -- Then move in y
  if y > 0 then for i = 1, y do safeForward() end end
  if y < 0 then turnRight(); turnRight(); for i = 1, -y do safeForward() end turnRight(); turnRight() end
end

-- Optimized BFS search for wood in a cubic area (3D)
local function searchAndCutWoodBFS(radius)
  local visited = {}
  local queue = {{x=0, y=0, z=0}}
  visited["0,0,0"] = true
  local directions = {
    {dx=0, dy=1, dz=0},  -- forward
    {dx=1, dy=0, dz=0},  -- right
    {dx=0, dy=-1, dz=0}, -- back
    {dx=-1, dy=0, dz=0}, -- left
    {dx=0, dy=0, dz=1},  -- up
    {dx=0, dy=0, dz=-1}  -- down
  }
  while #queue > 0 do
    local pos = table.remove(queue, 1)
    print("Searching at (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")")
    moveTo(pos.x, pos.y, pos.z)
    if findWoodNearby() then
      print("Wood found at (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")! Starting to cut...")
      cutWood()
      return true
    end
    for _, dir in ipairs(directions) do
      local nx, ny, nz = pos.x + dir.dx, pos.y + dir.dy, pos.z + dir.dz
      if math.abs(nx) <= radius and math.abs(ny) <= radius and math.abs(nz) <= radius then
        local key = nx..","..ny..","..nz
        if not visited[key] then
          visited[key] = true
          table.insert(queue, {x=nx, y=ny, z=nz})
        end
      end
    end
  end
  print("Finished searching area, no wood found.")
  return false
end

print("Searching for wood in a larger area...")
local radius = 100 -- You can increase this for a larger search area
local found = searchAndCutWoodBFS(radius)
if found then
  print("Wood found and cut!")
else
  print("No wood found in area of radius " .. radius)
end

