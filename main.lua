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
    level = Level.load("levels/jungle_rush/")
    player = Player.new()
    CANVAS = love.graphics.newCanvas(SIZE.x, SIZE.y)
end

local function fixedUpdate()
    player:update(level)

    -- Update camera
    do
        local targetCameraPosition = player.position - Vector.new(0, player.position.z) + player.velocity * 30
        targetCameraPosition.x = math.min(math.max(targetCameraPosition.x, SIZE.x / 2), level.width - SIZE.x / 2)
        targetCameraPosition.y = math.min(math.max(targetCameraPosition.y, SIZE.y / 2), level.height - SIZE.y / 2)
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

    local playerRegion = nil
    local playersToRender = { player }
    for i, layer in ipairs(level.layers) do
        -- Player rendering
        for j = #playersToRender, 1, -1 do
            local p = playersToRender[j]
            local pos = interpolate(p.position, p.lastPosition)
            local r, _, _, a = level:sampleDown(i, pos)
            if a >= 0.5 and pos.z + 2.0 < r then
                table.remove(playersToRender, j)
                p:draw(interpolate)

                -- Save the region (TODO: Filtering)
                local x, y = love.graphics.transformPoint(pos.x, pos.y - pos.z)
                local w, h = 12, 21
                x, y = math.floor(x - w / 2), math.floor(y - h + 3)
                x, y = math.min(math.max(x, 0), SIZE.x - 1), math.min(math.max(y, 0), SIZE.y - 1)
                w, h = math.min(w, SIZE.y - x), math.min(h, SIZE.y - y)
                if w > 0 and h > 0 then
                    love.graphics.setCanvas()
                    playerRegion = {
                        x = x, y = y,
                        image = love.graphics.newImage(CANVAS:newImageData(0, nil, x, y, w, h)),
                    }
                    love.graphics.setCanvas(CANVAS)
                end
            end
        end

        -- Draw layer
        love.graphics.draw(layer.image)
    end

    -- Finish rendering players
    for _, p in ipairs(playersToRender) do p:draw(interpolate) end

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
    local offset = ((Vector.new(w, h) - size) / 2):round()
    love.graphics.translate(offset.x, offset.y)
    love.graphics.scale(scale)
    love.graphics.draw(CANVAS)
end

