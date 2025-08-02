PLAYER_START = Vector.new(96, 96)
Player = {}
Player.__index = Player

function Player.new()
    local player = {
        size = Vector.new(10, 4),

        velocity = Vector.new(0, 0, 0),
        position = Vector.new(PLAYER_START, 0),
        lastPosition = nil,
        lastJump = false,
        shadowZ = 0,
        lastShadowZ = 0,
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
        local z, _, _ = sample3(self.position)
        grounded = self.position.z <= z + 0.06
        local targetVelocity = wasd * (sneak and 2 or grounded and 3 or 4)
        self.velocity.x = self.velocity.x + (targetVelocity.x - self.velocity.x) * 0.5
        self.velocity.y = self.velocity.y + (targetVelocity.y - self.velocity.y) * 0.5
        self.velocity.z = self.velocity.z - 0.8
        if jump and grounded then
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
    local w, h = 8, 16
    local x, y = round(pos.x - w / 2), round(pos.y - pos.z - h)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
end
