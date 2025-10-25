-- actions.lua
-- Minimal crash-resilient step tracker for CC:Tweaked turtles.
-- Keeps only one integer: the last completed step number.
-- Each call to :runStep() increments it after success, and uses fuel to detect if a step ran during a crash.
local Actions = {}
local localStep = 0
Actions.__index = Actions

local STATE_DIR = "/.state"

local directions = {
    "north",
    "east",
    "south",
    "west",
}

local function log(msg)
    -- log to file log.log
    print(msg)
    local fh = fs.open("/log.log", "a")
    fh.writeLine(msg)
    fh.close()
end

-- clear log file
local function clearLog()
    if fs.exists("/log.log") then
        fs.delete("/log.log")
    end
    log("Log cleared.")
end

local function safeUp()
    while true do
        local ok, reason = turtle.up()
        if ok then
          return ok, reason
        end
        log("Et voi liikkua ylös: " .. tostring(reason))
        turtle.digUp()
        sleep(0.2)
    end
end

local function safeDown()
    while true do
        local ok, reason = turtle.down()
        if ok then
          return ok, reason
        end
        log("Et voi liikkua alas: " .. tostring(reason))
        turtle.digDown()
        sleep(0.2)
    end
end

-- detect absolute facing direction
local function getAbsoluteFacing()
    local facingMap = {
        east = "west",
        west = "east",
        north = "south",
        south = "north",
    }
    -- select furnace from inventory
    local found = false
    for i = 1, 16 do
        turtle.select(i)
        local itemCount = turtle.getItemCount(i)
        if itemCount > 0 then
            local itemDetail = turtle.getItemDetail(i)
            if itemDetail and itemDetail.name == "minecraft:furnace" then
                found = true
                break
            end
        end
    end
    if not found then
        error("Furnace ei löydy inventaariosta.")
    end
    safeUp()
    -- aseta alas furnace
    turtle.select(1)
    turtle.placeDown()
    -- inspect furnace
    local success, furnaceData = turtle.inspectDown()
    safeDown()
    if furnaceData and furnaceData.state and furnaceData.state.facing then
        -- log all data
        log("Furnace data: " .. textutils.serialize(furnaceData))
        return facingMap[furnaceData.state.facing]
    else
        log("Furnace not found below!")
        return nil
    end
end

local function ensureDir(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part)
    end
    local built = ""
    for i = 1, #parts - 1 do
        built = built .. "/" .. parts[i]
        if not fs.exists(built) then
            fs.makeDir(built)
        end
    end
end

local function readFile(path)
    if not fs.exists(path) then
        return nil
    end
    local fh = fs.open(path, "r");
    if not fh then
        return nil
    end
    local s = fh.readAll();
    fh.close();
    return s
end

local function atomicWrite(path, contents)
    ensureDir(path)
    local tmp = path .. ".tmp"
    local fh = fs.open(tmp, "w")
    fh.write(contents);
    fh.flush();
    fh.close()
    if fs.exists(path) then
        fs.delete(path)
    end
    fs.move(tmp, path)
end

local function jsonEncode(tbl)
    if textutils.serializeJSON then
        return textutils.serializeJSON(tbl)
    else
        return textutils.serialize(tbl)
    end
end

local function jsonDecode(s)
    if not s then
        return nil
    end
    if textutils.unserializeJSON then
        local ok, v = pcall(textutils.unserializeJSON, s);
        if ok then
            return v
        end
    end
    return textutils.unserialize(s)
end

local function now_ms()
    if os.epoch then
        return os.epoch("utc")
    end
    return math.floor(os.time() * 1000)
end

local function getFuel()
    if turtle and turtle.getFuelLevel then
        local f = turtle.getFuelLevel();
        if f == "unlimited" then
            return math.huge
        end
        return f or 0
    end
    return 0
end

function Actions.new(name, opts)
    assert(type(name) == "string" and #name > 0)
    opts = opts or {}
    local self = setmetatable({}, Actions)
    self.name = name
    self.path = opts.path or (STATE_DIR .. "/" .. name .. ".json")
    self.startingStep = 0  -- for debugging, to see at which point of the program the turtle booted last
    self.state = {
        last_step = 0,
        pending = nil,
        version = 1,
        results = {},
    }
    local absoluteFacing = getAbsoluteFacing() or "north"
    for i, dir in ipairs(directions) do
        if dir == absoluteFacing then
            self.absoluteFacing = i
            break
        end
    end
    self.posState = {
        startFacing = self.absoluteFacing,
        facing = self.absoluteFacing,
        currPos = {x=0, y=0, z=0},
    }
    local s = readFile(self.path)
    if s then
        local t = jsonDecode(s);
        if type(t) == "table" then
            self.state = t
            self.posState = {
                startFacing = t.startFacing or self.absoluteFacing,
                facing = t.facing or self.absoluteFacing,
                currPos = t.currPos or {x=0, y=0, z=0},
            }
            -- remove positions from state
            self.state.facing = nil
            self.state.currPos = nil
            self.state.startFacing = nil
            self.startingStep = self.state.last_step or 0
        end
    end
    if not fs.exists(STATE_DIR) then
        fs.makeDir(STATE_DIR)
    end
    if self.startingStep == 0 then
        clearLog()
        log("absoluteFacing: " .. tostring(absoluteFacing))
    end
    self:reconcilePending()
    return self
end

function Actions:log(msg)
    print("[actions:log] " .. msg)
    log(msg)
end

function Actions:facingName()
    return directions[self.posState.facing]
end

function Actions:startFacingName()
    return directions[self.posState.startFacing]
end

function Actions:currPos()
    return self.posState.currPos
end

function Actions:moveTo(x, y, z, facing)
    local pos = self.posState.currPos
    local targetFacing = facing or self:facingName()
    while pos.y < y do
        self:safeUp()
    end
    while pos.y > y do
        self:safeDown()
    end
    while pos.x < x do
        while self:facingName() ~= "north" do
            self:turnRight()
        end
        self:safeForward()
    end
    while pos.x > x do
        while self:facingName() ~= "south" do
            self:turnRight()
        end
        self:safeForward()
    end
    while pos.z < z do
        while self:facingName() ~= "east" do
            self:turnRight()
        end
        self:safeForward()
    end
    while pos.z > z do
        while self:facingName() ~= "west" do
            self:turnRight()
        end
        self:safeForward()
    end
    while self:facingName() ~= targetFacing do
        self:turnRight()
    end
end

function Actions:faceRight()
    local zeroBased = self.posState.facing - 1
    zeroBased = (zeroBased + 1) % 4
    self.posState.facing = zeroBased + 1
end

function Actions:faceLeft()
    local zeroBased = self.posState.facing - 1
    zeroBased = (zeroBased + 3) % 4
    self.posState.facing = zeroBased + 1
end

function Actions:posForward()
    local pos = self.posState.currPos
    local facing = directions[self.posState.facing]
    if facing == "north" then
        pos.x = pos.x + 1
    elseif facing == "east" then
        pos.z = pos.z + 1
    elseif facing == "south" then
        pos.x = pos.x - 1
    elseif facing == "west" then
        pos.z = pos.z - 1
    end
end

function Actions:posBackward()
    local pos = self.posState.currPos
    local facing = directions[self.posState.facing]
    if facing == "north" then
        pos.x = pos.x - 1
    elseif facing == "east" then
        pos.z = pos.z - 1
    elseif facing == "south" then
        pos.x = pos.x + 1
    elseif facing == "west" then
        pos.z = pos.z + 1
    end
end

function Actions:posUp()
    local pos = self.posState.currPos
    pos.y = pos.y + 1
end

function Actions:posDown()
    local pos = self.posState.currPos
    pos.y = pos.y - 1
end

function Actions:save()
    atomicWrite(self.path, jsonEncode(self.state))
end

function Actions:reconcilePending()
    local p = self.state.pending;
    if not p then
        return
    end
    local cur = getFuel()
    local min_fuel = p.min_fuel or 0
    if cur < (p.fuel_before - min_fuel) then
        log("fuel spent during pending step " .. tostring(p.step) .. ", marking step as completed")
        self.state.last_step = p.step
        self.state.pending = nil
        self:save()
    elseif (p.facing_after and self.posState.facing == p.facing_after) then
        log("Already facing correct direction after pending step " .. tostring(p.step) .. ", marking step as completed")
        self.state.last_step = p.step
        self.state.pending = nil
        self:save()
    else
        log("fuel not spent during pending step " .. tostring(p.step) .. ", leaving step as pending")
    end
end

function Actions:runStep(fn, opts)
    log("x: " .. tostring(self.posState.currPos.x) .. ", y: " .. tostring(self.posState.currPos.y) .. ", z: " .. tostring(self.posState.currPos.z) .. ", facing: " .. tostring(self:facingName()))
    opts = opts or {}
    local min_fuel = opts.min_fuel or 0
    localStep = localStep + 1
    local step = localStep
    local plan = "RUNNING"
    if self.state.last_step >= step then
        plan = "SKIPPING"
    end
    if self.state.pending and self.state.pending.step == step then
        plan = "RECONCILING"
    end
    log(plan .. " step " .. step .. ", state: " .. jsonEncode(self.state))

    if self.state.pending and self.state.pending.step == step then
        self:reconcilePending()
        if self.state.last_step >= step then
            return true, nil
        end
        plan = "RUNNING"
        log(plan .. " step " .. step .. ", state: " .. jsonEncode(self.state))
    end

    -- Jos vaihe on jo valmis, palauta edellinen tulos
    if self.state.last_step >= step then
        if self.state.results then
          local res = self.state.results[tostring(step)]
          if res then
              local ok, value = pcall(textutils.unserialize, res.data)
              return res.ok, ok and value or res.data
          else
              return true, {name = "unknown"}
          end
        else
          return true, {name = "unknown"}
        end
    end

    local fuel_before = getFuel()
    local facing_after = nil
    if opts.turning then
        facing_after = self.posState.facing
        local zeroBased = facing_after - 1
        if opts.turning == "left" then
            facing_after = ((zeroBased + 3) % 4) + 1
        elseif opts.turning == "right" then
            facing_after = (zeroBased + 1) % 4 + 1
        end
    end
    self.state.pending = {
        step = step,
        fuel_before = fuel_before,
        min_fuel = min_fuel,
        facing_after = facing_after,
        ts = now_ms()
    }
    self:save()

    local ok, data = fn()
    -- Tallennetaan tulos vain jos pyydetty
    if opts.store_result then
        self.state.results[tostring(step)] = {
            ok = ok,
            data = {name = data.name}
        }
    end

    -- Merkitään askel valmiiksi
    self.state.last_step = step
    self.state.pending = nil
    self:save()

    return ok, data
end

function Actions:moveForward()
    local ret = self:runStep(function()
        return turtle.forward()
    end)
    self:posForward()
    return ret
end

function Actions:forward()
    local ret = self:moveForward()
    self:posForward()
    return ret
end

function Actions:moveBack()
    local ret = self:runStep(function()
        return turtle.back()
    end)
    self:posBackward()
    return ret
end

function Actions:back()
    local ret = self:moveBack()
    self:posBackward()
    return ret
end

function Actions:safeBack()
    local ret = self:runStep(function()
        while true do
            local ok, reason = turtle.back()
            if ok then
              return ok, reason
            end
            -- jos bensa loppu, heitetään error
            if reason and string.find(reason:lower(), "fuel") then
                error("Et voi liikkua ylös: " .. tostring(reason))
            end
            log("Et voi liikkua ylös: " .. tostring(reason))
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.dig()
            turtle.turnLeft()
            turtle.turnLeft()
            sleep(0.2)
        end
    end)
    self:posBackward()
    return ret
end

function Actions:safeForward()
    local ret = self:runStep(function()
        while true do
            local ok, reason = turtle.forward()
            if ok then
              return ok, reason
            end
            -- jos bensa loppu, heitetään error
            if reason and string.find(reason:lower(), "fuel") then
                error("Et voi liikkua eteenpäin: " .. tostring(reason))
            end
            log("Et voi liikkua eteenpäin: " .. tostring(reason))
            turtle.dig()
            sleep(0.2)
        end
    end)
    self:posForward()
    return ret
end

function Actions:moveUp()
    local ret = self:runStep(function()
        return turtle.up()
    end)
    self:posUp()
    return ret
end

function Actions:up()
    local ret = self:moveUp()
    self:posUp()
    return ret
end

function Actions:safeUp()
    local ret = self:runStep(function()
        while true do
            local ok, reason = turtle.up()
            if ok then
              return ok, reason
            end
            -- jos bensa loppu, heitetään error
            if reason and string.find(reason:lower(), "fuel") then
                error("Et voi liikkua ylös: " .. tostring(reason))
            end
            log("Et voi liikkua ylös: " .. tostring(reason))
            turtle.digUp()
            sleep(0.2)
        end
    end)
    self:posUp()
    return ret
end

function Actions:moveDown()
    local ret = self:runStep(function()
        return turtle.down()
    end)
    self:posDown()
    return ret
end

function Actions:down()
    local ret = self:moveDown()
    self:posDown()
    return ret
end

function Actions:safeDown()
    local ret = self:runStep(function()
        while true do
            local ok, reason = turtle.down()
            if ok then
              return ok, reason
            end
            -- jos bensa loppu, heitetään error
            if reason and string.find(reason:lower(), "fuel") then
                error("Et voi liikkua alas: " .. tostring(reason))
            end
            log("Et voi liikkua alas: " .. tostring(reason))
            turtle.digDown()
            sleep(0.2)
        end
    end)
    self:posDown()
    return ret
end

function Actions:turnLeft()
    local ret = self:runStep(function()
        return turtle.turnLeft()
    end, { turning = "left" })
    self:faceLeft()  -- we face left even if the step did not run
    return ret
end

function Actions:turnRight()
    local ret = self:runStep(function()
        local ret = turtle.turnRight()
        return ret
    end, { turning = "right" })
    self:faceRight()  -- we face right even if the step did not run
    return ret
end

function Actions:turnAround()
    self:runStep(function()
        return turtle.turnRight()
    end, { turning = "right" })
    self:faceRight()
    local ret = self:runStep(function()
        return turtle.turnRight()
    end, { turning = "right" })
    self:faceRight()
    return ret
end

function Actions:dig()
    return self:runStep(function()
        return turtle.dig()
    end)
end

function Actions:digUp()
    return self:runStep(function()
        return turtle.digUp()
    end)
end

function Actions:digDown()
    return self:runStep(function()
        return turtle.digDown()
    end)
end

function Actions:place()
    return self:runStep(function()
        return turtle.place()
    end)
end

function Actions:inspect()
    local ok, result = self:runStep(function()
        return turtle.inspect()
    end, {
        store_result = true
    })
    return ok, result
end

function Actions:inspectUp()
    local ok, result = self:runStep(function()
        return turtle.inspectUp()
    end, {
        store_result = true
    })
    return ok, result
end

function Actions:inspectDown()
    local ok, result = self:runStep(function()
        return turtle.inspectDown()
    end, {
        store_result = true
    })
    return ok, result
end

-- cycle helper: Using this prevents the step counter from growing indefinitely.
-- usage
-- while true do
--     tracker = Actions.new("looper")
--     tracker:cycle(function()
--         for i = 1, 3 do
--             turtle.dig()  -- here we can use turtle.dig() directly since block state tracking is not needed
--             tracker:moveForward()
--         end
--         -- more actions...
--     end)
-- end
-- after each cycle, the step counter is reset to 0.

function Actions:completeCycle()
    localStep = 0
    self.state.results = {}
    self.state.last_step = 0;
    self.state.pending = nil;
    -- We add position state to saved state for cycle persistence
    -- i.e. next cycle will start with these positions
    self.state.facing = self.posState.facing
    self.state.currPos = self.posState.currPos
    self.state.startFacing = self.posState.startFacing
    self:save()
end

function Actions.reset()
    -- delete all files in .state/
    if fs.exists(STATE_DIR) then
        for _, file in ipairs(fs.list(STATE_DIR)) do
            local path = STATE_DIR .. "/" .. file
            fs.delete(path)
        end
    end
end

function Actions:cycle(fn)
    fn()
    self:completeCycle()
end

return Actions
