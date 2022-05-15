

local _math = {}

--[[ MATH ]]

-- Normalize value between min and max.
-- https://www.youtube.com/watch?v=hJqRcExiBk0
function _math.norm(value, min, max)
    return (value - min) / (max - min)
end

-- Linear interpolation of normalized value.
-- https://www.youtube.com/watch?v=mAi2-LTC2CA
function _math.lerp(norm, min, max)
    return (max - min) * norm + min
end

-- Map a normalized value from one range onto a second range.
-- https://www.youtube.com/watch?v=FxAEXHGZSPA
function _math.map(value, sourceMin, sourceMax, destMin, destMax)
    return _math.lerp(_math.norm(value, sourceMin, sourceMax), destMin, destMax)
end

-- Restrict a value between a min and max value.
-- https://www.youtube.com/watch?v=A-uIFk_uWdw
function _math.clamp(value, min, max)
    return math.min(math.max(value, math.min(min, max)), math.max(min, max))
end

-- Determines if the there is an overlapping intersection between the two ranges (min1, max1) and (min2, max2).
-- https://youtu.be/NZHzgXFKfuY?t=806
function _math.intersect(min1, max1, min2, max2)
	return (math.max(min1, max1) >= math.min(min2, max2) and
 		    math.min(min1, max1) <= math.max(min2, max2))
end

-- Determines if value is within the range of min and max.
-- https://youtu.be/NZHzgXFKfuY?t=477
function _math.range(value, min, max)
	return (value >= math.min(min, max) and value <= math.max(min, max))
end

--[[ Determine the sign of the parameter. ]]
function _math.sign(x)
	if x < 0 then return -1 end
	if x == 0 then return 0 end
	if x > 0 then return 1 end
end

--[[ Returns the value that is nearest to the provided number. ]]
function _math.nearest(x, a, b)
	if math.abs(x - a) < math.abs(b - x) then return a else return b end
end

--[[ Rounds a number to the nearest integer number. ]]
function _math.round(x)
	return (x + 0.5 - (x + 0.5) % 1)
end

--[[ Generates a UUID variable. ]]
-- https://gist.github.com/jrus/3197011
math.randomseed(math.floor(os.time()*1E11))
function _math.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--==[[ Table Index ]]==--

--[[ Converts an row and col value into a table index. ]]
function _math.tableIndex(row, col, width)
	row = math.max(1, row)
	col = math.max(1, col)
	width = math.max(1, width)

	return (row - 1) * width + col
end

--[[ Converts an index into an x and y value. The start parameter allows the index to start either from 0 or 1. ]]
function _math.fromIndex(index, width, start)
	index = math.max(index, 0)
	width = math.max(width, 1)

	if not start then start = 0 end
	if not ((start == 0) or (start == 1)) then start = 0 end

	local x = (index % width) + start
	local y = math.floor(index / width) + start

	return x, y
end

--[[ Converts an x and y value into a index. ]]
function _math.toIndex(x, y, width)
	x = math.max(x, 0)
	y = math.max(y, 0)
	width = math.max(width, 1)

	return (y * width) + x
end

--==[[ Bitwise Operators ]]==--

local function _and_bit(left, right)
	return (left == 1 and right == 1) and 1 or 0
end

local function _or_bit(left, right)
	return (left == 1 or right == 1) and 1 or 0
end

local function _xor_bit(left, right)
	return (left + right) == 1  and 1 or 0
end

local function _base(left, right, operation)
	if left < right then
		left, right = right, left
	end

	local result = 0
	local shift = 1
	while not (left == 0) do
		local ra = left % 2
		local rb = right % 2
		result = shift * operation(ra, rb) + result
		shift = shift * 2
		left = math.modf(left / 2)
		right = math.modf(right / 2)
	end

	return result
end

function _math.bitAND(left, right)
	return _base(left, right, _and_bit)
end

function _math.bitOR(left, right)
	return _base(left, right, _or_bit)
end

function _math.bitXOR(left, right)
	return _base(left, right, _xor_bit)
end

function _math.bitNOT(left)
	return left > 0 and -(left + 1) or -left - 1
end

function _math.lshift(left, num)
	return left * (2 ^ num)
end

function _math.rshift(left, num)
	return math.floor(left / (2 ^ num))
end

return _math