
local _colors = {}
local ceil = math.ceil

--[[ Converts a hex string to a set of RGBA values. The string can start with or without a '#'. ]]
local function _hex2rgb(hex)
    if not (type(hex) == 'string') then return end

    hex = hex:gsub('#', '')
    if not (#hex == 6 or #hex == 8) then return end

    local r, g, b, a
    r, g, b = tonumber('0x'..hex:sub(1, 2)), tonumber('0x'..hex:sub(3, 4)), tonumber('0x'..hex:sub(5, 6))
    if #hex == 8 then a = tonumber('0x'..hex:sub(7, 8)) end
    if not a then a = 255 end

    if not (r and g and b) then return end

    return r, g, b, a
end

--[[ Converts the h,s,l,a (Hue, Saturation, Luminance, Alpha) to a set of RGBA values.]]
local function _hsl2rgb(h, s, l, a)
    h = h / 360
    s = s / 100
    l = l / 100

    -- If no saturation, return luminance*255 for each color channel.
    if s == 0 then return ceil(l*255), ceil(l*255), ceil(l*255) end

    local temp1 = (l < 0.5) and (l * (1.0 + s)) or (l + s - l * s)
    local temp2 = 2 * l - temp1

    local _h2c = function(c)
        if c < 0 then c = c + 1 end
        if c > 1 then c = c - 1 end

        if 6 * c < 1 then
            c = temp2 + (temp1 - temp2) * 6 * c
        elseif 2 * c < 1 then
            c = temp1
        elseif 3 * c < 2 then
            c = temp2 + (temp1 - temp2) * (0.66667 - c) * 6
        else
            c = temp2
        end

        return c
    end

    -- Red channel
    local r = _h2c(h + 0.33334)

    -- Green channel
    local g = _h2c(h)

    -- Blue channel
    local b = _h2c(h - 0.33334)

    return ceil(r * 255), ceil(g * 255), ceil(b * 255), a or 255
end

--[[ Confines a value within a minimum and maxium range. ]]
local function _clamp(value, min, max)
    return math.min(math.max(value, math.min(min, max)), math.max(min, max))
end


--[[
    PUBLIC
]]

--[[ Returns a color as a byte table without altering the original table. ]]
function _colors.asByte(color)
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.toByte : '..message, 2) end

    if color.byte then return color end
    return {byte=true, opacity=color.opacity, ceil(color[1] * 255), ceil(color[2] * 255), ceil(color[3] * 255), color[4] and ceil(color[4] * 255) or 255}
end

--[[ Returns a color as a table of normalized values without altering the original table. ]]
function _colors.asNorm(color)
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.toNorm : '..message, 2) end

    if not color.byte then return {byte=false, opacity=color.opacity, unpack(color)} end
    return {byte=false, opacity=color.opacity, color[1] / 255, color[2] / 255, color[3] / 255, color[4] and (color[4] / 255) or 1}
end

--[[
    Returns a normalized color table. If the color parameter is nil (which can happen in cases where setting
    the the color is optional), the method will fallback on the default color. In both cases, if the opacity
    value is passed in, the opacity key in the color will be set.
]]
function _colors.defaultColor(color, default, opacity)
    if not color then
        if not default then return end

        local success, message = _colors.validateColor(default)
        if not success then error('<utils>.colors.newColor : default color : '..message, 2) end

        _colors.setOpacity(default, opacity)
        return _colors.toNorm(default)
    end

    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.newColor : '..message, 2) end

    _colors.setOpacity(color, opacity)
    return _colors.toNorm(color)
end

--[[ Returns the active color as a normalized table. ]]
function _colors.getColor()
    return {byte=false, love.graphics.getColor()}
end

--[[ Return the active color as a byte table. ]]
function _colors.getColorBytes()
    return {byte=true, love.math.colorToBytes(love.graphics.getColor())}
end

--[[ Extracts the color channel value from a color and returns it as a normalized value. ]]
function _colors.getColorChannel(channel, color)
    if not channel or (channel == '') then return end
    channel = string.find("rgba", channel)
    if not channel or not color[channel] then return end

    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.getColorChannel : '..message, 2) end

    channel = color[channel]
    if color.byte then channel = channel / 255 end

    return channel
end

--[[ Extracts the color channel value from a color and returns it as a normalized value. ]]
function _colors.getColorChannelByte(channel, color)
    if not channel or (channel == '') then return end
    channel = string.find("rgba", channel)
    if not channel or not color[channel] then return end

    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.getColorChannelBytes : '..message, 2) end

    channel = color[channel]
    if not color.byte then channel = channel * 255 end

    return channel
end

--[[
    Returns the opacity for a color. The opacity will be determined by multiplying the color alpha channel
    with the table opacity value. If there is neither an alpha channel nor an opacity key, the method
    will assume the opacity equals 1 by default.
]]
function _colors.getOpacity(color)
    if not color then return end
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.getOpacity : '..message, 2) end

    local opacity = color.opacity
    local alpha = color.byte and (color[4] / 255) or color[4]

    if not opacity then return alpha or 1 end
    if not alpha then return opacity end

    return opacity * alpha
end

--[[
    Sets the opacity key for a color table. If no opacity value is passed in, the opacity key will
    be unset in the color table. The opacity parameter must be a value between 0 and 1.

    This method will only set the key, and will not modify the alpha channel of the color in any way.
]]
function _colors.setOpacity(color, opacity)
    if not color then return end

    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.setOpacity : '..message, 2) end

    color.opacity = nil
    if not opacity or not (type(opacity) == 'number') then return end

    color.opacity = _clamp(opacity, 0, 1)
    return color.opacity
end

--[[
    Sets the new active color in Love2D. Passing in no parameter will reset the active color
    to white with full opacity. The method will return the current active color as a color table.
    The byte flag of the color passed in will be used to determine the format of the returned
    color table.
]]
function _colors.setColor(color)
    if not color then
        local oldColor = {love.graphics.getColor()}
        love.graphics.setColor(1, 1, 1, 1)
        return oldColor
    end

    local oldColor = color.byte and _colors.getColorBytes() or _colors.getColor()
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.setColor : '..message, 2) end

    local r, g, b, a = unpack(color)
    if color.opacity then
        a = a * color.opacity
        a = color.byte and _clamp(a, 0, 255) or _clamp(a, 0, 1)
    end

    if color.byte then
        _colors.setColorBytes(r, g, b, a)
    else
        love.graphics.setColor(r, g, b, a)
    end

    return oldColor
end

--[[
    Set the current color for LOVE2D using byte values. Note: Use the regular love.graphics.setColor()
    if you want to set the color with normalized RGBA values.
]]
function _colors.setColorBytes(r, g, b, a)
    local success, message = _colors.validateColor({byte=true, r, g, b, a})
    if not success then error('<utils>.colors.rgba : '..message, 2) end

    local oldColor = _colors.getColorBytes()
    love.graphics.setColor(love.math.colorFromBytes(r, g, b, a))

    return oldColor
end

--[[ Converts the color table into a set of byte values. ]]
function _colors.toByte(color)
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.toByte : '..message, 2) end

    if color.byte then return color end

    color[1] = ceil(color[1] * 255)
    color[2] = ceil(color[2] * 255)
    color[3] = ceil(color[3] * 255)
    color[4] = color[4] and ceil(color[4] * 255)
    color.byte = true

    return color
end

--[[ Converts the color table into a set of normalized values. ]]
function _colors.toNorm(color)
    local success, message = _colors.validateColor(color)
    if not success then error('<utils>.colors.toNorm : '..message, 2) end

    if not color.byte then
        color.byte = false
        return color
    end

    color[1] = color[1] / 255
    color[2] = color[2] / 255
    color[3] = color[3] / 255
    color[4] = color[4] and (color[4] / 255)
    color.byte = false

    return color
end

--[[ Validates the color is correct. The color can either be in the format of a hex string, or a color table. ]]
function _colors.validateColor(color)
    if not (type(color) == 'table') then return false, 'color must be a table of rgba values' end
    if color.byte and not (type(color.byte) == 'boolean') then return false, 'color table byte flag must be a boolean' end
    if color.opacity and not(type(color.opacity) == 'number') then return false, 'color opacity must be a number' end

    if (#color < 3 or #color > 4) then
        return false, 'color table must contain a minimum of three rgb color values with a fourth optional alpha value'
    end

    local r, g, b, a = unpack(color)
    local type_r, type_g, type_b = type(r), type(g), type(b)
    local type_a = (a and type(a))

    if not (type_r == 'number' and type_g == 'number' and type_b == 'number') or (a and not (type_a == 'number')) then
        return false, 'color table must contain number values only'
    end

    local top = color.byte and 255 or 1

    color[1] = _clamp(color[1], 0, top)
    color[2] = _clamp(color[2], 0, top)
    color[3] = _clamp(color[3], 0, top)
    color[4] = a and _clamp(color[4], 0, top) or top

    -- Round up byte values to nearest integer.
    if color.byte then
        color[1] = ceil(color[1])
        color[2] = ceil(color[2])
        color[3] = ceil(color[3])
        color[4] = a and ceil(color[4]) or top
    end

    color.opacity = color.opacity and _clamp(color.opacity, 0, 1)

    return true, 'success'
end

color = {}
function color.rgba(r, g, b, a, opacity) return {byte=true, opacity=opacity, r, g, b, a or 255} end
function color.hsla(h, s, l, a, opacity) return {byte=true, opacity=opacity, _hsl2rgb(h, s, l, a)} end
function color.hex(str, opacity) return {byte=true, opacity=opacity, _hex2rgb(str)} end
function color.decimal(r, g, b, a, opacity) return {byte=false, opacity=opacity, r, g, b, a or 1} end
function color.byte2norm(r, g, b, a, opacity) return {byte=false, opacity=opacity, r/255, g/255, b/255, (a and (a/255) or 1)} end
function color.norm2byte(r, g, b, a, opacity) return {byte=true, opacity=opacity, r*255, g*255, b*255, (a and (a*255) or 255)} end

return _colors