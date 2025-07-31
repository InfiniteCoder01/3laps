Level = {}
Level.__index = Level
Level.LAYER_OFFSET = 8

function Level.load(path, layerCount)
    local level = { layers = {} }
    for i =1,layerCount do
        local data = love.image.newImageData(path .. i .. ".png")
        level.layers[i] = {
            background = { data:getPixel(0, 0) },
            image = love.graphics.newImage(data),
            map = love.image.newImageData(path .. i .. ".map.png"),
        }
    end
    setmetatable(level, Level)
    return level
end

function Level:getPixel(pos)
    local function sample(layer, uv)
        if not layer or uv.x < 0 or uv.y < 0 or uv.x >= layer.map:getWidth() or uv.y >= layer.map:getHeight() then
            return 0, 0, 0, 0
        end
        return layer.map:getPixel(uv.x, uv.y)
    end

    if math.fmod(pos.z, 1) >= 0.9 then
        pos = Vector.new(pos.x, pos.y, math.floor(pos.z + 0.1))
    end

    for layerZ = math.floor(pos.z), 1, -1 do
        local layer = self.layers[layerZ]

        for offset = Level.LAYER_OFFSET, 0, -1 do
            local uv = Vector.new(pos.x, pos.y - layerZ * Level.LAYER_OFFSET - offset)
            local r, g, b, a = sample(layer, uv)
            if a < 0.5 then goto continue end
            if math.abs(r - offset / Level.LAYER_OFFSET) < 0.5 / Level.LAYER_OFFSET then
                r = layerZ + r
                return r, g, b
            end
            ::continue::
        end
    end
    return 1, 0, 0
end
