 -- vector metatable:
Vector = {}
Vector.__index = Vector

-- vector constructor:
function Vector.new(x, y, z)
  if getmetatable(x) == Vector then
  	return Vector.new(x.x, x.y, y)
  end

  local v = {x = x or 0, y = y or 0, z = z}
  setmetatable(v, Vector)
  return v
end

-- vector addition:
function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y, a.z and b.z and a.z + b.z)
end

-- vector subtraction:
function Vector.__sub(a, b)
  return Vector.new(a.x - b.x, a.y - b.y, a.z and b.z and a.z - b.z)
end

-- multiplication of a vector by a scalar:
function Vector.__mul(a, b)
  if type(a) == "number" then
    return Vector.new(b.x * a, b.y * a, b.z and b.z * a)
  elseif type(b) == "number" then
    return Vector.new(a.x * b, a.y * b, a.z and a.z * b)
  else
    return Vector.new(a.x * b.x, a.y * b.y, a.z and b.z and a.z * b.z)
  end
end

-- dividing a vector by a scalar:
function Vector.__div(a, b)
   if type(b) == "number" then
      return Vector.new(a.x / b, a.y / b, a.z and a.z / b)
   else
      error("Invalid argument types for vector division.")
   end
end

-- vector equivalence comparison:
function Vector.__eq(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

-- vector not equivalence comparison:
function Vector.__ne(a, b)
	return not Vector.__eq(a, b)
end

-- unary negation operator:
function Vector.__unm(a)
	return Vector.new(-a.x, -a.y, a.z and -a.z)
end

-- vector < comparison:
function Vector.__lt(a, b)
	return a.x < b.x and a.y < b.y and (not a.z or not b.z or a.z < b.z)
end

-- vector <= comparison:
function Vector.__le(a, b)
	return a.x <= b.x and a.y <= b.y and (not a.z or not b.z or a.z <= b.z)
end

-- vector value string output:
function Vector.__tostring(v)
	local function ff(x)
		if math.abs(x) < 1 then
			return tostring(x)
		else
			return string.format("%.2f", x)
		end
	end

	return "(" .. ff(v.x) .. ", " .. ff(v.y) .. (v.z and ", " .. ff(v.z) or "") .. ")"
end

-- Vector rounding
function Vector.round(v)
	local function round(x) return math.floor(x + 0.5) end
	return Vector.new(round(v.x), round(v.y), v.z and round(v.z))
end

function Vector.floor(v)
	return Vector.new(math.floor(v.x), math.floor(v.y), v.z and math.floor(v.z))
end

-- vector magnitude:
function Vector.magnitudeSquared(v)
	return v.x * v.x + v.y * v.y + (v.z and v.z * v.z or 0)
end

function Vector.magnitude(v)
	return math.sqrt(v:magnitudeSquared())
end

-- vector normalization:
function Vector.normalized(v)
	return v / v:magnitude()
end

