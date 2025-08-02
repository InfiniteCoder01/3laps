Level = {}
Level.__index = Level

function Level.load(path, count)
    local level = { layers = {} }
    for i = 1, count do
        local data = love.image.newImageData(path .. (i * 2 - 1) .. ".png")
        local map = love.image.newImageData(path .. (i * 2) .. ".png")
        level.layers[i] = {
            image = love.graphics.newImage(data),
            map = map,
        }
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
    return math.ceil(r * 255 / 8), g, b, a
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
            return math.ceil(r * 255 / 8), g, b, a
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
    return 1, 0, 0
end
