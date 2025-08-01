PLAYER_START = Vector.new(96, 96 + Level.LAYER_OFFSET)
Player = {}
Player.__index = Player

function Player.new()
    local player = {
        size = Vector.new(10, 4),

        velocity = Vector.new(0, 0, 0),
        position = Vector.new(PLAYER_START, 1),
        lastPosition = nil,
        shadowZ = 1,
        lastShadowZ = 1,
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

    do
        local z, _, _ = sample3(self.position)
        local targetVelocity = wasd * 3
        self.velocity.x = self.velocity.x + (targetVelocity.x - self.velocity.x) * 0.5
        self.velocity.y = self.velocity.y + (targetVelocity.y - self.velocity.y) * 0.5
        self.velocity.z = self.velocity.z - 0.1
        if love.keyboard.isDown("space") and self.position.z <= z + 0.06 then
            self.velocity.z = 0.3
        end
    end

    -- Integrate
    local function moveInSteps(v, stepSize)
        local STEP_HEIGHT = 0.1
        local EPS = 0.0001

        local total = math.abs(v.x + v.y + v.z) / stepSize
        local step = v / total
        local start = self.position
        for i = 1, math.ceil(total) do
            local pos = start + step * math.min(i, total)
            local z = sample3(pos)
            if pos.z <= z then
                if v.z ~= 0 then
                    self.position.z = z + EPS
                    return true
                end

                if pos.z + STEP_HEIGHT >= z then
                    pos.z = z + EPS
                else return true end
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

function Player:interpolatedLayer(interpolate)
    return math.floor(interpolate(self.position, self.lastPosition).z)
end

function Player:draw(interpolate)
    local pos = interpolate(self.position, self.lastPosition)

    -- Shadow
    local shadowZ = interpolate(self.shadowZ, self.lastShadowZ)
    love.graphics.setColor(0, 0.0, 0.0, 0.3)
    love.graphics.ellipse("fill", pos.x, pos.y - shadowZ * Level.LAYER_OFFSET, self.size.x / 2, self.size.y / 2)

    -- Player
    love.graphics.setColor(1, 0, 0, 1)
    local w, h = 8, 16
    local x, y = pos.x - w / 2, pos.y - pos.z * Level.LAYER_OFFSET - h
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
end
