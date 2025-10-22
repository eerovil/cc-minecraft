-- actions.lua
-- Minimal crash-resilient step tracker for CC:Tweaked turtles.
-- Keeps only one integer: the last completed step number.
-- Each call to :runStep() increments it after success, and uses fuel to detect if a step ran during a crash.

local Actions = {}
Actions.__index = Actions

local STATE_DIR = "/.state"

local function ensureDir(path)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do table.insert(parts, part) end
  local built = ""
  for i = 1, #parts - 1 do
    built = built .. "/" .. parts[i]
    if not fs.exists(built) then fs.makeDir(built) end
  end
end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local fh = fs.open(path, "r"); if not fh then return nil end
  local s = fh.readAll(); fh.close(); return s
end

local function atomicWrite(path, contents)
  ensureDir(path)
  local tmp = path .. ".tmp"
  local fh = fs.open(tmp, "w")
  fh.write(contents); fh.flush(); fh.close()
  if fs.exists(path) then fs.delete(path) end
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
  if not s then return nil end
  if textutils.unserializeJSON then
    local ok,v=pcall(textutils.unserializeJSON,s); if ok then return v end
  end
  return textutils.unserialize(s)
end

local function now_ms()
  if os.epoch then return os.epoch("utc") end
  return math.floor(os.time()*1000)
end

local function getFuel()
  if turtle and turtle.getFuelLevel then
    local f=turtle.getFuelLevel(); if f=="unlimited" then return math.huge end
    return f or 0
  end
  return 0
end

function Actions.new(name, opts)
  assert(type(name)=="string" and #name>0)
  opts=opts or {}
  local self=setmetatable({},Actions)
  self.name=name
  self.path=opts.path or (STATE_DIR.."/"..name..".json")
  self.state={ last_step=0, pending=nil, version=1 }
  local s=readFile(self.path)
  if s then local t=jsonDecode(s); if type(t)=="table" then self.state=t end end
  if not fs.exists(STATE_DIR) then fs.makeDir(STATE_DIR) end
  self:reconcilePending()
  return self
end

function Actions:save()
  atomicWrite(self.path,jsonEncode(self.state))
end

function Actions:reconcilePending()
  local p=self.state.pending; if not p then return end
  local cur=getFuel()
  local min_fuel=p.min_fuel or 1
  if cur<(p.fuel_before-min_fuel) then
    self.state.last_step=p.step
    self.state.pending=nil
    self:save()
  end
end

function Actions:runStep(fn,opts)
  opts=opts or {}
  local min_fuel=opts.min_fuel or 1
  local step=self.state.last_step+1

  if self.state.pending and self.state.pending.step==step then
    self:reconcilePending()
    if self.state.last_step>=step then return "resumed-completed" end
  end

  if self.state.last_step>=step then return "skipped" end

  local fuel_before=getFuel()
  self.state.pending={step=step,fuel_before=fuel_before,min_fuel=min_fuel,ts=now_ms()}
  self:save()

  local ok,err=pcall(fn)
  if not ok then
    self:reconcilePending()
    if self.state.last_step>=step then return "auto-completed" end
    error("Step #"..step.." failed: "..tostring(err))
  end
  self.state.last_step=step
  self.state.pending=nil
  self:save()
  return "done"
end

function Actions:moveForward(n)
  n=n or 1
  return self:runStep(function()
    for i=1,n do assert(turtle.forward(),"blocked") end
  end,{min_fuel=n})
end

function Actions:turnLeft()
  return self:runStep(function() turtle.turnLeft() end,{min_fuel=0})
end

function Actions:turnRight()
  return self:runStep(function() turtle.turnRight() end,{min_fuel=0})
end

function Actions:dig()
  return self:runStep(function() turtle.dig() end,{min_fuel=0})
end

function Actions:place()
  return self:runStep(function() turtle.place() end,{min_fuel=0})
end

function Actions:completeCycle()
  self.state.last_step=0; self.state.pending=nil; self:save()
end

function Actions:cycle(fn)
  local ok,err=pcall(fn)
  if not ok then error(err) end
  self:completeCycle()
end

function Actions:print()
  print("[actions] step="..tostring(self.state.last_step))
  if self.state.pending then print("pending:",textutils.serialize(self.state.pending)) end
end

return Actions
