local SuoniKaivaja = {}
SuoniKaivaja.__index = SuoniKaivaja

function SuoniKaivaja.new(tracker, interestingBlocks)
    local self = setmetatable({}, SuoniKaivaja)
    self.tracker = tracker
    self.interestingBlocks = interestingBlocks
    return self
end

-- funktio: kerro onko blokki mielenkiintoinen
function SuoniKaivaja:isInterestingBlock(blockName)
    for _, name in ipairs(SuoniKaivaja.interestingBlocks) do
        if blockName == name then
            return true
        end
    end
    return false
end

function SuoniKaivaja:kaivaSuoni(direction)
    if direction == "up" then
        self.tracker:digUp()
        self.tracker:up()
        self:inspectSurroundings()
        self.tracker:down()
    elseif direction == "down" then
        self.tracker:digDown()
        self.tracker:down()
        self:inspectSurroundings()
        self.tracker:up()
    elseif direction == "forward" then
        self.tracker:dig()
        self.tracker:safeForward()
        self:inspectSurroundings()
        self.tracker:back()
    end
end

function SuoniKaivaja:inspectSurroundings()
    -- ensin katso ylös
    local successUp, dataUp = turtle:inspectUp()
    if successUp and self:isInterestingBlock(dataUp.name) then
        print("Yläpuolella: " .. (dataUp.name or "tuntematon"))
        self:kaivaSuoni("up")
    end
    -- sitten katso alas
    local successDown, dataDown = turtle:inspectDown()
    if successDown and self:isInterestingBlock(dataDown.name) then
        print("Alapuolella: " .. (dataDown.name or "tuntematon"))
        self:kaivaSuoni("down")
    end
    -- sitten katso eteen
    local successAhead, dataDown = turtle:inspect()
    if successAhead and self:isInterestingBlock(dataDown.name) then
        print("Alapuolella: " .. (dataDown.name or "tuntematon"))
        self:kaivaSuoni("down")
    end
    -- katso oikealle, taakse, vasemmalle
    for i = 1, 3 do
        self.tracker:turnRight()
        local successSide, dataSide = turtle:inspect()
        if successSide and self:isInterestingBlock(dataSide.name) then
            print("Sivulla: " .. (dataSide.name or "tuntematon"))
            self:kaivaSuoni("forward")
        end
    end
    self.tracker:turnRight()
    print("Ei mielenkiintoista ympärillä.")
    return nil
end

return SuoniKaivaja
