local player = {
    size = Vector.new(10, 4),

    velocity = Vector.new(0, 0, 0),
    position = Vector.new(128, 128, 1),
    lastPosition = Vector.new(128, 128, 1),
    cameraPosition = Vector.new(128, 128),
    lastCameraPosition = Vector.new(128, 128),
    shadowZ = 1,
    lastShadowZ = 1,
}

function player:update(level)
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
        local z, _, _ = level:getPixel(self.position)
        local targetVelocity = wasd * 3
        self.velocity.x = self.velocity.x + (targetVelocity.x - self.velocity.x) * 0.5
        self.velocity.y = self.velocity.y + (targetVelocity.y - self.velocity.y) * 0.5
        self.velocity.z = self.velocity.z - 0.2
        if love.keyboard.isDown("space") and self.position.z <= z + 0.06 then
            self.velocity.z = 0.6
        end
    end

    -- Sample pixels thoughout the whole collider
    function sample3(pos)
        local zLeft = level:getPixel(pos - Vector.new(self.size.x / 2, 0, 0))
        local zMid = level:getPixel(pos)
        local zRight = level:getPixel(pos + Vector.new(self.size.x / 2, 0, 0))
        return math.max(zLeft, zMid, zRight)
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

    -- Update camera
    do
        self.lastCameraPosition = self.cameraPosition
        local targetCameraPosition = self.position + self.velocity * 30
        self.cameraPosition = self.cameraPosition + (targetCameraPosition - self.cameraPosition) * 0.05
    end
end

return player
