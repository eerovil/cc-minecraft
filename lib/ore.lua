-- SuoniKaivaja.lua
local SuoniKaivaja = {}
SuoniKaivaja.__index = SuoniKaivaja

local RIGHT = { north="east", east="south", south="west", west="north" }
local LEFT  = { north="west", west="south", south="east", east="north" }
local DX = { north=0,  east=1, south=0,  west=-1 }
local DZ = { north=-1, east=0, south=1,  west=0  }

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
    self.pos = {x=0, y=0, z=0}
    self.facing = "north"
    self.visited = { [key(0,0,0)] = true }
    self.endMiningCallback = endMiningCallback
    return self
end

-- --- orientaatio & liike seuraaminen ---
function SuoniKaivaja:_turnRight()
    self.tracker:turnRight()
    self.facing = RIGHT[self.facing]
end

function SuoniKaivaja:_turnLeft()
    self.tracker:turnLeft()
    self.facing = LEFT[self.facing]
end

function SuoniKaivaja:_moveForward()
    if self.tracker:safeForward() then
        self.pos.x = self.pos.x + DX[self.facing]
        self.pos.z = self.pos.z + DZ[self.facing]
        return true
    end
end

function SuoniKaivaja:_moveBack()
    if self.tracker:safeBack() then
        self.pos.x = self.pos.x - DX[self.facing]
        self.pos.z = self.pos.z - DZ[self.facing]
        return true
    end
end

function SuoniKaivaja:_moveUp()
    if self.tracker:safeUp() then
        self.pos.y = self.pos.y + 1
        return true
    end
end

function SuoniKaivaja:_moveDown()
    if self.tracker:safeDown() then
        self.pos.y = self.pos.y - 1
        return true
    end
end

-- --- apu ---
function SuoniKaivaja:_neighborPos(dir)
    local x,y,z = self.pos.x, self.pos.y, self.pos.z
    if dir == "up" then return x, y+1, z end
    if dir == "down" then return x, y-1, z end
    return x + DX[self.facing], y, z + DZ[self.facing]
end

function SuoniKaivaja:_markVisited(x,y,z)
    self.visited[key(x,y,z)] = true
end

function SuoniKaivaja:_isVisited(x,y,z)
    return self.visited[key(x,y,z)] == true
end

-- --- suonen seuraaminen ---
function SuoniKaivaja:_digAndMove(dir)
    if dir == "up" then
        self.tracker:digUp()
        if not self:_moveUp() then return false end
    elseif dir == "down" then
        self.tracker:digDown()
        if not self:_moveDown() then return false end
    elseif dir == "forward" then
        self.tracker:dig()
        if not self:_moveForward() then return false end
    end
    local x,y,z = self.pos.x, self.pos.y, self.pos.z
    self:_markVisited(x,y,z)
    return true
end

function SuoniKaivaja:_backtrack(dir)
    if dir == "up" then self:_moveDown()
    elseif dir == "down" then self:_moveUp()
    elseif dir == "forward" then self:_moveBack()
    end
end

function SuoniKaivaja:_getNeighborPositions()
    local faces = {"north","east","south","west"}
    local DX = {north=0, east=1, south=0, west=-1}
    local DZ = {north=-1, east=0, south=1, west=0}
    local idx = {north=1, east=2, south=3, west=4}

    local pos = {}
    local fi = idx[self.facing]
    for r=0,3 do
        local f = faces[((fi-1 + r)%4)+1]
        table.insert(pos, {
            x = self.pos.x + DX[f],
            y = self.pos.y,
            z = self.pos.z + DZ[f],
            dx = DX[f],
            dy = 0,
            dz = DZ[f],
            dir = f,   -- halutessasi tiedoksi mikä suunta tämä on
            visited = self:_isVisited(
                self.pos.x + DX[f],
                self.pos.y,
                self.pos.z + DZ[f]
            )
        })
    end
    return pos
end

function SuoniKaivaja:_quickCheck()
    -- check ahead, up, down and mark visited if not interesting
    for _, dir in ipairs({"forward", "up", "down"}) do
        local ok, data
        if dir == "forward" then
            ok, data = self.tracker:inspect()
            if not ok or not self.interesting[data.name] then
                local nx,ny,nz = self:_neighborPos("forward")
                self:_markVisited(nx,ny,nz)
            end
        elseif dir == "up" then
            ok, data = self.tracker:inspectUp()
            if not ok or not self.interesting[data.name] then
                local nx,ny,nz = self:_neighborPos("up")
                self:_markVisited(nx,ny,nz)
            end
        elseif dir == "down" then
            ok, data = self.tracker:inspectDown()
            if not ok or not self.interesting[data.name] then
                local nx,ny,nz = self:_neighborPos("down")
                self:_markVisited(nx,ny,nz)
            end
        end
    end
end

function SuoniKaivaja:_scanAround(cameFrom)
    if self.endMiningCallback and self.endMiningCallback() then
        print("Lopetetaan kaivuu ulkoisesta syystä.")
        self.interesting = {}  -- tyhjennä mielenkiintoiset blokit, jotta lopetetaan
        return
    end
    self:_quickCheck()

    -- ylös
    if cameFrom ~= "up" then
        local ok, data = self.tracker:inspectUp()
        local nx,ny,nz = self:_neighborPos("up")
        if ok and self.interesting[data.name] then
            print("Ylös: "..data.name)
            if self:_digAndMove("up") then
                self:_scanAround("down")
                self:_backtrack("up")
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    end

    -- alas
    if cameFrom ~= "down" then
        local ok, data = self.tracker:inspectDown()
        local nx,ny,nz = self:_neighborPos("down")
        if ok and self.interesting[data.name] then
            print("Alas: "..data.name)
            if self:_digAndMove("down") then
                self:_scanAround("up")
                self:_backtrack("down")
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    end

    -- eteen
    local ok, data = self.tracker:inspect()
    local nx,ny,nz = self:_neighborPos("forward")
    if ok and self.interesting[data.name] then
        print("Eessä: "..data.name)
        if self:_digAndMove("forward") then
            self:_scanAround("back")
            self:_backtrack("forward")
        end
    else
        -- ei mielenkiintoinen, mutta merkitään käydyksi
        self:_markVisited(nx,ny,nz)
    end

    local neighborPositions = self:_getNeighborPositions()
    local taakse = neighborPositions[3]
    local oikealle = neighborPositions[2]
    local vasemmalle = neighborPositions[4]
    local startFacing = self.facing

    -- jos interesting on tyhjä, lopeta
    if next(self.interesting) == nil then
        return
    end

    print("Naapurit: taakse.visited="..tostring(taakse.visited)..
          ", oikealle.visited="..tostring(oikealle.visited)..
          ", vasemmalle.visited="..tostring(vasemmalle.visited))
    if (not taakse.visited or (not oikealle.visited and not vasemmalle.visited)) then
        -- neljä seinää
        self:_turnRight()
        for i = 1, 3 do
            local ok, data = self.tracker:inspect()
            local nx,ny,nz = self:_neighborPos("forward")
            if ok and self.interesting[data.name] then
                print("Eessä: "..data.name)
                if self:_digAndMove("forward") then
                    self:_scanAround("back")
                    self:_backtrack("forward")
                end
            else
                -- ei mielenkiintoinen, mutta merkitään käydyksi
                self:_markVisited(nx,ny,nz)
            end
            self:_turnRight()
        end
    elseif not oikealle.visited then
        -- käänny oikealle
        self:_turnRight()
        local ok, data = self.tracker:inspect()
        local nx,ny,nz = self:_neighborPos("forward")
        if ok and self.interesting[data.name] then
            print("Eessä (oikea): "..data.name)
            if self:_digAndMove("forward") then
                self:_scanAround("back")
                self:_backtrack("forward")
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    elseif not vasemmalle.visited then
        -- käänny vasemmalle
        self:_turnLeft()
        local ok, data = self.tracker:inspect()
        local nx,ny,nz = self:_neighborPos("forward")
        if ok and self.interesting[data.name] then
            print("Eessä (vasen): "..data.name)
            if self:_digAndMove("forward") then
                self:_scanAround("back")
                self:_backtrack("forward")
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    end

    -- palauta alkuorientaatio
    while self.facing ~= startFacing do self:_turnRight() end
end

-- julkinen pääfunktio
function SuoniKaivaja:aloita()
    self:_scanAround(nil)
    print("Ei lisää mielenkiintoisia blokkeja ympärillä.")
end

return SuoniKaivaja
