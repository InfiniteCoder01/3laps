require("vector")
local player = require("player")
require("level")

-- "Emulation" settings
TICK_RATE = 20
TICK_TIME = 1 / TICK_RATE
SIZE = Vector.new(160, 144)

love.window.setMode(800, 600, { resizable = true })

local level
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    level = Level.load("levels/test/", 2)
end

local function fixedUpdate()
    player:update(level)
end

local function draw(interpolate)
    -- Set camera
    do
        local pos = interpolate(player.cameraPosition, player.lastCameraPosition)
        local offset = SIZE / 2 - pos
        love.graphics.translate(offset.x, offset.y)
    end

    local function shadow(position, size)
        love.graphics.setColor(0, 0.0, 0.0, 0.3)
        love.graphics.ellipse("fill", math.floor(position.x), math.floor(position.y - position.z * Level.LAYER_OFFSET), size.x / 2, size.y / 2)
    end

    love.graphics.clear(level.layers[1].background)
    
    local playerPos = interpolate(player.position, player.lastPosition)
    local playerLayer = math.floor(playerPos.z)
    local function drawPlayer()
        shadow(Vector.new(playerPos.x, playerPos.y, interpolate(player.shadowZ, player.lastShadowZ)), player.size)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", math.floor(playerPos.x) - 7, math.floor(playerPos.y - playerPos.z * Level.LAYER_OFFSET - 30), 14, 30)
    end

    for i, layer in ipairs(level.layers) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(layer.image)
        -- Draw player
        if i == playerLayer then drawPlayer() end
    end
    if playerLayer > #level.layers then drawPlayer() end
end

-- Update (emulate tick rate)
local time = 0
local lastUpdate = 0
function love.update(dt)
    time = time + dt
    while lastUpdate + TICK_TIME <  time do
        fixedUpdate()
        lastUpdate = lastUpdate + TICK_TIME
    end
end

-- Draw (emulate resolution & aspect ratio)
function love.draw()
    -- Scaling & transforms
    do
        local w, h = love.graphics.getDimensions()
        local scale = math.min(w / SIZE.x, h / SIZE.y)
        local size = SIZE * scale
        local offset = (Vector.new(w, h) - size) / 2
        love.graphics.translate(offset.x, offset.y)
        love.graphics.scale(scale)
        love.graphics.setScissor(offset.x, offset.y, size.x, size.y)
    end

    -- Position interpolation
    local function interpolate(current, last)
        return last + (current - last) * (time - lastUpdate) / TICK_TIME
    end

    draw(interpolate)

    love.graphics.setScissor()
end

