PLAYER_START = Vector.new(96, 96)
Player = { sfx = {} }
Player.__index = Player

function Player.load()
    Player.sfx.checkpoint = love.audio.newSource("sfx/checkpoint.wav", "static")
    Player.sfx.checkpoint:setVolume(0.6)
    Player.sfx.boost = love.audio.newSource("sfx/boost.wav", "static")
    Player.sfx.boost:setVolume(0.6)
end

function Player.new()
    local player = {
        size = Vector.new(8, 4),

        velocity = Vector.new(0, 0, 0),
        position = Vector.new(PLAYER_START, 0),
        lastPosition = nil,
        lastJump = false,
        shadowZ = 0,
        lastShadowZ = 0,

        checkpoint = 0,
        checkpointTime = 0,
        splits = {},
        lap = 0,
        totalTime = 0,
    }
    setmetatable(player, Player)
    return player
end

function Player:update(level)
    -- Sample pixels thoughout the whole collider
    local function sample3(pos)
        local zLeft, gLeft, bLeft = level:getPixel(pos - Vector.new(self.size.x / 2, 0, 0))
        local z, g, b = level:getPixel(pos)
        local zRight, gRight, bRight = level:getPixel(pos + Vector.new(self.size.x / 2, 0, 0))
        if zLeft > z then z, g, b = zLeft, gLeft, bLeft end
        if zRight > z then z, g, b = zRight, gRight, bRight end
        return z, g, b
    end

    -- Player controls
    local function ikey(keys)
        for key in keys:gmatch("%w+") do
            if love.keyboard.isDown(key) then return 1 end
        end
        return 0
    end

    local wasd = Vector.new(
        ikey("d l right") - ikey("a h left"),
        ikey("s j down") - ikey("w k up")
    )
    local jump = love.keyboard.isDown("space")
    local sneak = love.keyboard.isDown("lshift")

    local grounded
    do
        local z, g, b = sample3(self.position)
        grounded = self.position.z <= z + 0.06

        -- Checkpoints
        if self.lap > 0 and self.lap <= Level.TOTAL_LAPS then
            self.checkpointTime = self.checkpointTime + 0.05
            self.totalTime = self.totalTime + 0.05
        end

        local function fmtTime(time)
            return string.format("%02d:%02d.%02d\n",
                            math.floor(time / 60),
                            math.floor(time) % 60,
                            math.floor(math.fmod(time, 1) * 100.5))
        end

        local function fmtSplit(list)
            local time = self.checkpointTime
            self.checkpointTime = 0

            local split = self.splits[self.checkpoint]
            self.splits[self.checkpoint] = time
            if split then time = time - split end

            local timeStr = fmtTime(math.abs(time))
            if split then
                if time <= 0 then
                     table.insert(list, {0, 1, 0})
                     table.insert(list, "-" .. timeStr)
                else
                    table.insert(list, {1, 0, 0})
                    table.insert(list, "+" .. timeStr)
                end
            else
                table.insert(list, {1, 1, 1})
                table.insert(list, timeStr)
            end
        end

        if (self.checkpoint == 0 or self.checkpoint == level.checkpoints) and g == 1 then
            self.checkpoint = g
            self.lap = self.lap + 1
            if self.lap == Level.TOTAL_LAPS + 1 then
                TEXT:setTitle({
                    {1, 1, 1}, "FINISH!\n",
                    {0, 0, 1}, fmtTime(self.totalTime),
                }, 65536)
            else
                local title = {
                    {1, 1, 1}, string.format("LAP %d/%d\n", self.lap, Level.TOTAL_LAPS),
                }
                if self.lap > 1 then
                    fmtSplit(title)
                    -- local lapTime = 0
                    -- for _, split in pairs(self.splits) do lapTime = lapTime + split end
                    -- table.insert(title, {1, 1, 1})
                    -- table.insert(title, "LAP: " .. fmtTime(lapTime))
                end
                TEXT:setTitle(title)
            end
            Player.sfx.checkpoint:play()
        elseif g == self.checkpoint + 1 then
            self.checkpoint = g
            local title = {
                {1, 1, 1}, string.format("CHECKPOINT %d/%d\n", self.checkpoint - 1, level.checkpoints - 1),
            }
            fmtSplit(title)
            TEXT:setTitle(title)
            Player.sfx.checkpoint:play()
        end

        -- Controls
        local targetVelocity = wasd * (sneak and 2 or grounded and 3 or 4)
        self.velocity.x = self.velocity.x + (targetVelocity.x - self.velocity.x) * 0.5
        self.velocity.y = self.velocity.y + (targetVelocity.y - self.velocity.y) * 0.5
        self.velocity.z = self.velocity.z - 0.8
        if jump and grounded then
            if b == 255 then
                Player.sfx.boost:play()
                self.velocity = self.velocity * 10
            end
            self.velocity.z = 3.6
        elseif not jump and self.lastJump and self.velocity.z > 0 then
            self.velocity.z = self.velocity.z * 0.5
        end
    end

    self.lastJump = jump

    -- Integrate
    local function moveInSteps(v, stepSize)
        local STEP_HEIGHT = 1.0

        local total = math.abs(v.x + v.y + v.z) / stepSize
        local step = v / total
        local start = self.position
        for i = 1, math.ceil(total) do
            local pos = start + step * math.min(i, total)
            local z = sample3(pos)
            if pos.z <= z then
                if v.z ~= 0 then
                    if v.z < 0 then self.position.z = z end
                    return true
                end

                if pos.z + STEP_HEIGHT >= z then
                    pos.z = z
                else return true end
            elseif sneak and grounded and pos.z - STEP_HEIGHT > z and v.z == 0 then
                return true
            end
            self.position = pos
        end
        return false
    end

    self.lastPosition = self.position
    if moveInSteps(self.velocity * Vector.new(1, 0, 0), 1) then self.velocity.x = 0 end
    if moveInSteps(self.velocity * Vector.new(0, 1, 0), 1) then self.velocity.y = 0 end
    if moveInSteps(self.velocity * Vector.new(0, 0, 1), 0.05) then self.velocity.z = 0 end

    -- Shadow
    self.lastShadowZ = self.shadowZ
    self.shadowZ = sample3(self.position)
end

function Player:draw(interpolate)
    local pos = interpolate(self.position, self.lastPosition)
	local function round(x) return math.floor(x + 0.5) end

    -- Shadow
    local shadowZ = interpolate(self.shadowZ, self.lastShadowZ)
    love.graphics.setColor(0, 0.0, 0.0, 0.3)
    love.graphics.ellipse("fill",
        round(pos.x), round(pos.y - shadowZ),
        self.size.x / 2, self.size.y / 2)

    -- Player
    love.graphics.setColor(1, 0, 0, 1)
    local w, h = 8, 10
    local x, y = round(pos.x - w / 2), round(pos.y - pos.z - h)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
end
