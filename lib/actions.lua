-- actions.lua
-- Minimal crash-resilient step tracker for CC:Tweaked turtles.
-- Keeps only one integer: the last completed step number.
-- Each call to :runStep() increments it after success, and uses fuel to detect if a step ran during a crash.
local Actions = {}
local localStep = 0
Actions.__index = Actions

local STATE_DIR = "/.state"

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
    self.state = {
        last_step = 0,
        pending = nil,
        version = 1,
        results = {}
    }
    local s = readFile(self.path)
    if s then
        local t = jsonDecode(s);
        if type(t) == "table" then
            self.state = t
        end
    end
    if not fs.exists(STATE_DIR) then
        fs.makeDir(STATE_DIR)
    end
    self:reconcilePending()
    return self
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
        self.state.last_step = p.step
        self.state.pending = nil
        self:save()
    end
end

function Actions:runStep(fn, opts)
    opts = opts or {}
    local min_fuel = opts.min_fuel or 0
    localStep = localStep + 1
    local step = localStep
    print("[actions] step " .. step .. ", state: " .. jsonEncode(self.state))

    if self.state.pending and self.state.pending.step == step then
        self:reconcilePending()
        if self.state.last_step >= step then
            return true, nil
        end
    end

    -- Jos vaihe on jo valmis, palauta edellinen tulos
    if self.state.last_step >= step then
        local res = self.state.results[step]
        if res then
            local ok, value = pcall(textutils.unserialize, res.data)
            return true, ok and value or res.data
        else
            return true, nil
        end
    end

    local fuel_before = getFuel()
    self.state.pending = {
        step = step,
        fuel_before = fuel_before,
        min_fuel = min_fuel,
        ts = now_ms()
    }
    self:save()

    local ok, data = fn()
    if not ok then
        self:reconcilePending()
        if self.state.last_step >= step then
            -- Jos askel ehti silti mennä läpi, palauta viimeisin tallennettu tulos
            local res = self.state.results[step]
            if res then
                local ok2, value = pcall(textutils.unserialize, res.data)
                return true, value or res.data
            end
        end
        error("Step #" .. step .. " failed: " .. tostring(data))
    end

    -- Tallennetaan tulos vain jos pyydetty
    if opts.store_result then
        local encoded
        local ok_s, enc = pcall(textutils.serialize, data)
        encoded = ok_s and enc or tostring(data)
        self.state.results[step] = {
            data = encoded
        }
    end

    -- Merkitään askel valmiiksi
    self.state.last_step = step
    self.state.pending = nil
    self:save()

    return true, data
end

function Actions:moveForward()
    return self:runStep(function()
        return turtle.forward()
    end)
end

function Actions:forward()
    return self:moveForward()
end

function Actions:moveBack()
    return self:runStep(function()
        return turtle.back()
    end)
end

function Actions:back()
    return self:moveBack()
end

function Actions:safeForward()
    return self:runStep(function()
        while true do
            local ok, reason = turtle.forward()
            if ok then
              return ok, reason
            end
            -- jos bensa loppu, heitetään error
            if reason and string.find(reason:lower(), "fuel") then
                error("Et voi liikkua eteenpäin: " .. tostring(reason))
            end
            print("Et voi liikkua eteenpäin: " .. tostring(reason))
            turtle.dig()
            sleep(0.2)
        end
    end)
end

function Actions:moveUp()
    return self:runStep(function()
        return turtle.up()
    end)
end

function Actions:up()
    return self:moveUp()
end

function Actions:moveDown()
    return self:runStep(function()
        return turtle.down()
    end)
end

function Actions:down()
    return self:moveDown()
end

function Actions:turnLeft()
    return self:runStep(function()
        return turtle.turnLeft()
    end)
end

function Actions:turnRight()
    return self:runStep(function()
        return turtle.turnRight()
    end)
end

function Actions:turnAround()
    self:runStep(function()
        return turtle.turnRight()
    end)
    return self:runStep(function()
        return turtle.turnRight()
    end)
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
    self:save()
end

function Actions:cycle(fn)
    local ok, err = pcall(fn)
    if not ok then
        error(err)
    end
    self:completeCycle()
end

function Actions:print()
    print("[actions] step=" .. tostring(self.state.last_step))
    if self.state.pending then
        print("pending:", textutils.serialize(self.state.pending))
    end
end

return Actions
