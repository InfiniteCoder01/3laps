require("vector")
require("level")
require("player")

-- "Emulation" settings
TICK_RATE = 20
TICK_TIME = 1 / TICK_RATE
SIZE = Vector.new(160, 144)

love.window.setMode(SIZE.x * 4, SIZE.y * 4, { resizable = true })

local level
local player
local camera = { lastPosition = nil, position = nil }
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    level = Level.load("levels/jungle_rush/", 3)
    player = Player.new()

    CANVAS = love.graphics.newCanvas(SIZE.x, SIZE.y)
end

local function fixedUpdate()
    player:update(level)

    -- Update camera
    do
        local targetCameraPosition = player.position - Vector.new(0, player.position.z * Level.LAYER_OFFSET) + player.velocity * 30
        if not camera.position then
            camera.position = targetCameraPosition
            camera.lastPosition = camera.position
        else
            local lerp = player.velocity:magnitudeSquared() < 0.05 and 0.3 or 0.05
            camera.lastPosition = camera.position
            camera.position = camera.position + (targetCameraPosition - camera.position) * lerp
        end
    end
end

local function draw(interpolate)
    -- Set camera
    love.graphics.push()
    do
        local pos = interpolate(camera.position, camera.lastPosition)
        local offset = SIZE / 2 - pos
        love.graphics.translate(offset.x, offset.y)
    end

    love.graphics.clear(level.layers[1].background)

    local playerRegion = nil
    for i, layer in ipairs(level.layers) do
        -- Draw player (possibly occluded)
        if player:interpolatedLayer(interpolate) == i - 1 then
            player:draw(interpolate)

            -- Save the region
            love.graphics.setCanvas()
            local pos = interpolate(player.position, player.lastPosition)
            local x, y = love.graphics.transformPoint(pos.x, pos.y - pos.z * Level.LAYER_OFFSET)
            local w, h = 12, 21
            x, y = math.floor(x - w / 2), math.floor(y - h + 3)

            playerRegion = {
                x = x, y = y,
                image = love.graphics.newImage(CANVAS:newImageData(0, nil, x, y, w, h)),
            }
            love.graphics.setCanvas(CANVAS)
        end

        -- Draw layer
        love.graphics.draw(layer.image)
    end
    if player:interpolatedLayer(interpolate) >= #level.layers then player:draw(interpolate) end
    love.graphics.pop()

    if playerRegion then
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.draw(playerRegion.image, playerRegion.x, playerRegion.y)
        love.graphics.setColor(1, 1, 1, 1)
    end
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

    draw(interpolate)

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

