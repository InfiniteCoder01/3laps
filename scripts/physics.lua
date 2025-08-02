-- A script to compute how velocity changes and how far you can possibly jump
require("vector")

local position = Vector.new(0, 0, 0)
local velocity = Vector.new(0, 0, 0)
local lastJump = false

for tick = 1, 20 do
    -- Simulated inputs
    local wasd = Vector.new(1, 0)
    local jump = true
    local sneak = false

    -- Simulate movement
    local grounded = position.z <= 0.06
    local targetVelocity = wasd * (sneak and 2 or grounded and 3 or 4)
    velocity.x = velocity.x + (targetVelocity.x - velocity.x) * 0.5
    velocity.y = velocity.y + (targetVelocity.y - velocity.y) * 0.5
    velocity.z = velocity.z - 0.8
    if jump and grounded then
        velocity.z = 3.6
    elseif not jump and lastJump and velocity.z > 0 then
        velocity.z = velocity.z * 0.5
    end
    lastJump = jump

    -- "Integrate"
    position = position + velocity
    if position.z < 0 then
        position.z = 0
        velocity.z = 0
    end

    print(string.format("Tick #%d: %s, velocity: %s", tick, position, velocity))
end
