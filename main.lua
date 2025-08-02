require("vector")
require("level")
require("player")

-- "Emulation" settings
TICK_RATE = 20
TICK_TIME = 1 / TICK_RATE
SIZE = Vector.new(160, 144)

-- Title
local font = love.graphics.newImageFont("fonts/big.png",
    " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"")
local fontSmall = love.graphics.newFont("fonts/pansyhand.ttf", 16, "normal")

TEXT = {
    time = 0.0,
    title = love.graphics.newText(font),
    actionbar = love.graphics.newText(font),
}

function TEXT:setTitle(title, time)
    self.title:setf(title, SIZE.x, "center")
    self.time = time or 1
end

love.window.setTitle("3 Laps")
love.window.setMode(SIZE.x * 4, SIZE.y * 4, { resizable = true })

local level
local player
local camera = { lastPosition = nil, position = nil, velocity = Vector.new(0, 0) }
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    level = Level.load("levels/jungle_rush/")
    player = Player.new()
    CANVAS = love.graphics.newCanvas(SIZE.x, SIZE.y)
end

local function fixedUpdate()
    TEXT.time = TEXT.time - 0.05
    player:update(level)

    -- Update camera
    camera.lastPosition = camera.position
    camera.velocity = camera.velocity + (player.velocity - camera.velocity) * 0.1
    camera.position = player.position - Vector.new(0, player.position.z) + camera.velocity * 5
    camera.position.x = math.min(math.max(camera.position.x, SIZE.x / 2), level.height - SIZE.x / 2)
    camera.position.y = math.min(math.max(camera.position.y, SIZE.y / 2), level.height - SIZE.y / 2)
    if not camera.lastPosition then camera.lastPosition = camera.position end
end

local function draw(interpolate)
    -- Set camera
    love.graphics.push()
    do
        local pos = interpolate(camera.position, camera.lastPosition):round()
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
            local r1, _, _, a1 = level:sampleDown(i, pos - Vector.new(p.size.x / 2, 0, 0))
            local r2, _, _, a2 = level:sampleDown(i, pos)
            local r3, _, _, a3 = level:sampleDown(i, pos + Vector.new(p.size.x / 2, 0, 0))
            if (a1 >= 0.5 and pos.z + 2.0 < r1) or
               (a2 >= 0.5 and pos.z + 2.0 < r2) or
               (a3 >= 0.5 and pos.z + 2.0 < r3) then
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

    if TEXT.time > 0 then
        love.graphics.draw(TEXT.title, 0, SIZE.y / 3 * 2)
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

