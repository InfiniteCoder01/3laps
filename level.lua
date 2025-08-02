Level = {}
Level.__index = Level
Level.TOTAL_LAPS = 3

function Level.load(path)
    local level = { layers = {}, checkpoints = 0 }
    local files = love.filesystem.getDirectoryItems(path)
    for _, file in ipairs(files) do
        local idxStr = file:gmatch("%d+")()
        if idxStr then -- Layer image
            local idx = tonumber(idxStr)
            local li = math.floor((idx + 1) / 2)
            file = path .. "/" .. file

            if not level.layers[li] then level.layers[li] = {} end
            if idx % 2 == 1 then level.layers[li].image = love.graphics.newImage(file)
            else
                local map = love.image.newImageData(file)
                level.layers[li].map = map
                for y = 0, map:getHeight() - 1 do
                    for x = 0, map:getWidth() - 1 do
                        local _, g, _, _ = map:getPixel(x, y)
                        level.checkpoints = math.max(level.checkpoints, math.floor(g * 255 / 16))
                    end
                end
            end
        end
    end
    level.width = level.layers[1].map:getWidth()
    level.height = level.layers[1].map:getHeight()
    setmetatable(level, Level)
    return level
end

function Level:sample(layer, uv)
    layer = self.layers[layer]
    uv = uv:floor()
    if not layer or uv.x < 0 or uv.y < 0 or uv.x >= layer.map:getWidth() or uv.y >= layer.map:getHeight() then
        return 256, 0, 0, 1
    end
    local r, g, b, a = layer.map:getPixel(uv.x, uv.y)
    return math.floor(r * 255 / 8), math.floor(g * 255 / 16), b, a
end

function Level:sampleDown(layer, uv)
    layer = self.layers[layer]
    uv = uv:floor()
    if not layer or uv.x < 0 or uv.y < 0 or uv.x >= layer.map:getWidth() or uv.y >= layer.map:getHeight() then
        return 256, 0, 0, 1
    end
    for y = uv.y, layer.map:getHeight() - 1 do
        local r, g, b, a = layer.map:getPixel(uv.x, y)
        if a >= 0.5 then
            return math.floor(r * 255 / 8), math.floor(g * 255 / 16), b, a
        end
    end
    return 0, 0, 0, 0
end

function Level:getPixel(pos)
    for i = #self.layers, 1, -1 do
        local r, g, b, a = self:sample(i, pos)
        if a >= 0.5 then
            if a > 0.9 or not (pos.z and pos.z + 5.0 < r) then
                return r, g, b
            end
        end
    end
    return 0, 0, 0
end
