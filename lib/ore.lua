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
    if self.tracker:back() then
        self.pos.x = self.pos.x - DX[self.facing]
        self.pos.z = self.pos.z - DZ[self.facing]
        return true
    end
end

function SuoniKaivaja:_moveUp()
    if self.tracker:up() then
        self.pos.y = self.pos.y + 1
        return true
    end
end

function SuoniKaivaja:_moveDown()
    if self.tracker:down() then
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

function SuoniKaivaja:_scanAround(cameFrom)
    if self.endMiningCallback and self.endMiningCallback() then
        print("Lopetetaan kaivuu ulkoisesta syystä.")
        return
    end

    -- ylös
    if cameFrom ~= "up" then
        local ok, data = turtle.inspectUp()
        local nx,ny,nz = self:_neighborPos("up")
        if ok and self.interesting[data.name] then
            if not self:_isVisited(nx,ny,nz) then
                print("Ylös: "..data.name)
                if self:_digAndMove("up") then
                    self:_scanAround("down")
                    self:_backtrack("up")
                end
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    end

    -- alas
    if cameFrom ~= "down" then
        local ok, data = turtle.inspectDown()
        local nx,ny,nz = self:_neighborPos("down")
        if ok and self.interesting[data.name] then
            if not self:_isVisited(nx,ny,nz) then
                print("Alas: "..data.name)
                if self:_digAndMove("down") then
                    self:_scanAround("up")
                    self:_backtrack("down")
                end
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    end

    local neighborPositions = self:_getNeighborPositions()
    local taakse = neighborPositions[2]
    local oikealle = neighborPositions[1]
    local vasemmalle = neighborPositions[3]
    print("Naapurit: taakse.visited="..tostring(taakse.visited)..
          ", oikealle.visited="..tostring(oikealle.visited)..
          ", vasemmalle.visited="..tostring(vasemmalle.visited))
    if (not taakse.visited or (not oikealle.visited and not vasemmalle.visited)) then
        -- neljä seinää
        local startFacing = self.facing
        for i = 1, 4 do
            local ok, data = turtle.inspect()
            local nx,ny,nz = self:_neighborPos("forward")
            if ok and self.interesting[data.name] then
                if not self:_isVisited(nx,ny,nz) then
                    print("Eessä: "..data.name)
                    if self:_digAndMove("forward") then
                        self:_scanAround("back")
                        self:_backtrack("forward")
                    end
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
        local ok, data = turtle.inspect()
        local nx,ny,nz = self:_neighborPos("forward")
        if ok and self.interesting[data.name] then
            if not self:_isVisited(nx,ny,nz) then
                print("Eessä (oikea): "..data.name)
                if self:_digAndMove("forward") then
                    self:_scanAround("back")
                    self:_backtrack("forward")
                end
            end
        else
            -- ei mielenkiintoinen, mutta merkitään käydyksi
            self:_markVisited(nx,ny,nz)
        end
    elseif not vasemmalle.visited then
        -- käänny vasemmalle
        self:_turnLeft()
        local ok, data = turtle.inspect()
        local nx,ny,nz = self:_neighborPos("forward")
        if ok and self.interesting[data.name] then
            if not self:_isVisited(nx,ny,nz) then
                print("Eessä (vasen): "..data.name)
                if self:_digAndMove("forward") then
                    self:_scanAround("back")
                    self:_backtrack("forward")
                end
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
