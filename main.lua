require("vector")
require("level")
local player = require("player")

-- "Emulation" settings
TICK_RATE = 20
TICK_TIME = 1 / TICK_RATE
SIZE = Vector.new(160, 144)

love.window.setMode(SIZE.x * 4, SIZE.y * 4, { resizable = true })

local level
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    level = Level.load("levels/jungle_rush/", 3)

    CANVAS = love.graphics.newCanvas(SIZE.x, SIZE.y)
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
        love.graphics.ellipse("fill", position.x, position.y - position.z * Level.LAYER_OFFSET, size.x / 2, size.y / 2)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.clear(level.layers[1].background)
    
    local playerPos = interpolate(player.position, player.lastPosition)
    local playerLayer = math.floor(playerPos.z)
    local function drawPlayer()
        shadow(Vector.new(playerPos.x, playerPos.y, interpolate(player.shadowZ, player.lastShadowZ)), player.size)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", playerPos.x - 4, playerPos.y - playerPos.z * Level.LAYER_OFFSET - 16, 8, 16)
        love.graphics.setColor(1, 1, 1, 1)
    end

    for i, layer in ipairs(level.layers) do
        love.graphics.draw(layer.image)
        -- Draw player
        if i == playerLayer then drawPlayer() end
    end
    if playerLayer > #level.layers then drawPlayer() end
end

-- Update (emulate tick rate)
local time = 0
local lastUpdate = -TICK_TIME
function love.update(dt)
    time = time + dt
    while lastUpdate + TICK_TIME <= time do
        fixedUpdate()
        lastUpdate = lastUpdate + TICK_TIME
    end
end

-- Draw (emulate resolution & aspect ratio)
function love.draw()
    -- Position interpolation
    local function interpolate(current, last)
        return last + (current - last) * (time - lastUpdate) / TICK_TIME
    end

    love.graphics.setCanvas(CANVAS)
    love.graphics.push()

    draw(interpolate)

    love.graphics.pop()
    love.graphics.setCanvas()

    -- Scaling & transforms
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / SIZE.x, h / SIZE.y)
    local size = SIZE * scale
    local offset = (Vector.new(w, h) - size) / 2
    love.graphics.translate(offset.x, offset.y)
    love.graphics.scale(scale)
    love.graphics.draw(CANVAS)
end

