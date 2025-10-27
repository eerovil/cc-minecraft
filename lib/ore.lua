-- SuoniKaivaja.lua
local SuoniKaivaja = {}
SuoniKaivaja.__index = SuoniKaivaja

local RIGHT = { north="east", east="south", south="west", west="north" }
local LEFT  = { north="west", west="south", south="east", east="north" }
local DX = { north=1,  east=0, south=-1,  west=0 }
local DZ = { north=0, east=1, south=0,  west=-1  }

local directions = {
    "north",
    "east",
    "south",
    "west",
}

local function key(x,y,z)
    return table.concat({x,y,z}, ",")
end

local function makeSet(list)
    local s = {}
    for _, v in ipairs(list or {}) do s[v] = true end
    return s
end

local function opposite(dir)
    if dir == "up" then return "down" end
    if dir == "down" then return "up" end
    if dir == "forward" then return "back" end
end

-- Luo uusi SuoniKaivaja
function SuoniKaivaja.new(tracker, interestingBlocks, endMiningCallback)
    local self = setmetatable({}, SuoniKaivaja)
    self.tracker = tracker
    self.interesting = makeSet(interestingBlocks)
    local currPos = self.tracker:currPos()
    self.visited = { [key(currPos.x, currPos.y, currPos.z)] = true }
    self.surelyInteresting = {}
    self.endMiningCallback = endMiningCallback
    return self
end

function SuoniKaivaja:isInterestingBlock(dir)
    local ok, _ = self.tracker:inspectAndCall(dir, function(ok, data)
        if ok and self.interesting[data.name] then
            return 1, nil
        else
            return 0, nil
        end
    end)
    return ok == 1
end

-- --- apu ---
function SuoniKaivaja:_neighborPos(dir)
    local currPos = self.tracker:currPos()
    if dir == "up" then return currPos.x, currPos.y+1, currPos.z end
    if dir == "down" then return currPos.x, currPos.y-1, currPos.z end
    local currFacing = self.tracker:facingName()
    if dir == "forward" then
        dir = currFacing
    else
        local zeroBasedFacing = self.tracker.posState.facing - 1
        if dir == "right" then
            dir = directions[(zeroBasedFacing + 1) % 4 + 1]
        elseif dir == "left" then
            dir = directions[(zeroBasedFacing - 1 + 4) % 4 + 1]
        elseif dir == "back" then
            dir = directions[(zeroBasedFacing + 2) % 4 + 1]
        end
    end
    return currPos.x + DX[dir], currPos.y, currPos.z + DZ[dir]
end

function SuoniKaivaja:_markVisited(x,y,z)
    self.visited[key(x,y,z)] = true
    self.surelyInteresting[key(x,y,z)] = false
end

function SuoniKaivaja:_markInteresting(x,y,z)
    self.surelyInteresting[key(x,y,z)] = true
end

function SuoniKaivaja:_isVisited(x,y,z)
    return self.visited[key(x,y,z)] == true
end

function SuoniKaivaja:_isSurelyInteresting(x,y,z)
    return self.surelyInteresting[key(x,y,z)] == true
end

function SuoniKaivaja:_posIsSurelyInteresting(pos)
    local x,y,z = pos.x, pos.y, pos.z
    return self.surelyInteresting[key(x,y,z)] == true
end

-- --- suonen seuraaminen ---
function SuoniKaivaja:_digAndMove(dir)
    if dir == "up" then
        self.tracker:digUp()
        if not self.tracker:safeUp() then return false end
    elseif dir == "down" then
        self.tracker:digDown()
        if not self.tracker:safeDown() then return false end
    elseif dir == "forward" then
        self.tracker:dig()
        if not self.tracker:safeForward() then return false end
    end
    local currPos = self.tracker:currPos()
    local x,y,z = currPos.x, currPos.y, currPos.z
    self:_markVisited(x,y,z)
    return true
end

function SuoniKaivaja:_backtrack(dir)
    if dir == "up" then self.tracker:safeDown()
    elseif dir == "down" then self.tracker:safeUp()
    elseif dir == "forward" then self.tracker:safeBack()
    end
end

function SuoniKaivaja:_getNeighborPositions()
    local facing = self.tracker:facingName()
    local pos = {}
    local currPos = self.tracker:currPos()

    for _, d in ipairs({"forward", "right", "back", "left"}) do
        local nx,ny,nz = self:_neighborPos(d)
        table.insert(pos, {x=nx, y=ny, z=nz, visited=self:_isVisited(nx,ny,nz), dir=d})
    end

    return pos
end

function SuoniKaivaja:_quickCheck()
    -- check ahead, up, down and mark visited if not interesting
    local checkResults = {
        forward = nil,
        up = nil,
        down = nil,
        right = nil,
        left = nil,
        back = nil
    }
    for _, dir in ipairs({"forward", "up", "down"}) do
        local ok, data
        if dir == "forward" then
            if not self:isInterestingBlock("forward") then
                local nx,ny,nz = self:_neighborPos("forward")
                self:_markVisited(nx,ny,nz)
                checkResults.forward = false
            else
                checkResults.forward = true
            end
        elseif dir == "up" then
            if not self:isInterestingBlock("up") then
                local nx,ny,nz = self:_neighborPos("up")
                self:_markVisited(nx,ny,nz)
                checkResults.up = false
            else
                checkResults.up = true
            end
        elseif dir == "down" then
            if not self:isInterestingBlock("down") then
                local nx,ny,nz = self:_neighborPos("down")
                self:_markVisited(nx,ny,nz)
                checkResults.down = false
            else
                checkResults.down = true
            end
        end
    end
    return checkResults
end

function SuoniKaivaja:_scanAround()
    local startFacing = self.tracker:facingName()
    -- jos kaivaminen on kestänyt liian kauan, lopeta
    if self.tracker:tooBigState() then
        print("Lopetetaan kaivuu, koska tila on liian suuri.")
        self.interesting = {}  -- tyhjennä mielenkiintoiset blokit, jotta lopetetaan
        return
    end

    if self.endMiningCallback and self.endMiningCallback() then
        print("Lopetetaan kaivuu ulkoisesta syystä.")
        self.interesting = {}  -- tyhjennä mielenkiintoiset blokit, jotta lopetetaan
        return
    end
    local checkResults = self:_quickCheck()
    local neighborPositions = self:_getNeighborPositions()
    local taakse = neighborPositions[3]
    local oikealle = neighborPositions[2]
    local vasemmalle = neighborPositions[4]

    -- update checkResults based on visited
    if taakse.visited then checkResults.back = false end
    if oikealle.visited then checkResults.right = false end
    if vasemmalle.visited then checkResults.left = false end
    if self:_posIsSurelyInteresting(taakse) then checkResults.back = true end
    if self:_posIsSurelyInteresting(oikealle) then checkResults.right = true end
    if self:_posIsSurelyInteresting(vasemmalle) then checkResults.left = true end

    -- if all neighbors checkResults are false (NOT NIL), return
    if checkResults.forward == false
       and checkResults.up == false
       and checkResults.down == false
       and checkResults.right == false
       and checkResults.left == false
       and checkResults.back == false then
        return
    end

    -- update any nil values.
    if (checkResults.back == nil or (checkResults.right == nil and checkResults.left == nil)) then
        self.tracker:turnRight()
        local resFacing = "right"
        for i = 1, 3 do
            local forwardIsInteresting = self:isInterestingBlock("forward")
            local nx,ny,nz = self:_neighborPos("forward")
            if forwardIsInteresting then
                checkResults[resFacing] = true
                self:_markInteresting(nx,ny,nz)
            else
                checkResults[resFacing] = false
                -- ei mielenkiintoinen, mutta merkitään käydyksi
                self:_markVisited(nx,ny,nz)
            end
            self.tracker:turnRight()
            if resFacing == "right" then resFacing = "back"
            elseif resFacing == "back" then resFacing = "left"
            elseif resFacing == "left" then resFacing = "forward" end
        end
    elseif (checkResults.right == nil) then
        self.tracker:turnRight()
        local rightIsInteresting = self:isInterestingBlock("forward")
        local nx,ny,nz = self:_neighborPos("forward")
        if rightIsInteresting then
            checkResults.right = true
            self:_markInteresting(nx,ny,nz)
        else
            checkResults.right = false
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
        self.tracker:turnLeft()
    elseif (checkResults.left == nil) then
        self.tracker:turnLeft()
        local leftIsInteresting = self:isInterestingBlock("forward")
        local nx,ny,nz = self:_neighborPos("forward")
        if leftIsInteresting then
            checkResults.left = true
            self:_markInteresting(nx,ny,nz)
        else
            checkResults.left = false
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
        self.tracker:turnRight()
    end

    -- jos interesting on tyhjä, lopeta
    if next(self.interesting) == nil then
        self.tracker:turnTowards(startFacing)
        return
    end

    -- valitse joku true-suunta ja mene sinne
    for _, dir in ipairs({"forward", "up", "down", "right", "left", "back"}) do
        local resultDir = dir
        if checkResults[dir] then
            self.tracker:log("Moving " .. dir .. " which is interesting.")
            if dir == "right" then
                self.tracker:turnRight()
                resultDir = "forward"
            elseif dir == "left" then
                self.tracker:turnLeft()
                resultDir = "forward"
            elseif dir == "back" then
                self.tracker:turnRight()
                self.tracker:turnRight()
                resultDir = "forward"
            end
            if self:_digAndMove(resultDir) then
                self:_scanAround()
                self:_backtrack(resultDir)
            end
            self.tracker:turnTowards(startFacing)
        end
    end
    self.tracker:turnTowards(startFacing)
end

-- julkinen pääfunktio
function SuoniKaivaja:aloita()
    self:_scanAround(nil)
    print("Ei lisää mielenkiintoisia blokkeja ympärillä.")
end

return SuoniKaivaja
