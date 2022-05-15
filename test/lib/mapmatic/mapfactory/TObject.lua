local lib = (...):gsub("mapfactory.TObject$", '')

local utils = require(lib .. "utils")
local Class = require(lib .. "class")

local TObject = Class{__name="TObject"}

--===================
-- Object Information
--===================

--- Returns the id for the map item. The id is automatically set when the object is added to a custom layer.
---@return integer id
function TObject:getId()
    return self.id or 0
end

--- Returns the name of the map item.
---@return string name
function TObject:getName()
    return self.name or ""
end

function TObject:setName(name)
    if self.name == nil then return end
    assert(type(name) == "string", "setName : param #1 must be a string type")
    self.name = name
end

--=========
-- Position
--=========

--- Returns the tracking point for the object without its offsets.
---@return number x, number y
function TObject:getPosition()
    return self:getX(), self:getY()
end

--- Returns the x-coordinate of the map item without its offset.
---@return number x
function TObject:getX()
    return self.x or 0
end

--- Returns the y-coordinate of the map item without its offset.
---@return number y
function TObject:getY()
    return self.y or 0
end

--- Sets the tracking point for the object.
---@param px number Object x-coordinate
---@param py number Object y-coordinate
function TObject:setPosition(px, py)
    if self.x == nil then return end
    if self.y == nil then return end
    assert(type(px) == "number", "setPosition : param #1 must be a number type")
    assert(type(py) == "number", "setPosition : param #2 must be a number type")
    self.x = px
    self.y = py
end

--- Sets the x-coordinate for the map item.
---@param px number The new x-coordinate for the map item
function TObject:setX(px)
    if self.x == nil then return end
    assert(type(px) == "number", "setX : param #1 must be a number type")
    self.x = px
end

--- Sets the y-coordinate for the map item.
---@param py number The new y-coordinate for the map item
function TObject:setY(py)
    if self.y == nil then return end
    assert(type(py) == "number", "setY : param #1 must be a number type")
    self.y = py
end

--- Moves the object by the specified amount in the x and y directions.
---@param dx number The amount to move the map item in the x direction
---@param dy number THe amount to move the map item in the y direction
function TObject:moveBy(dx, dy)
    if self.x == nil then return end
    if self.y == nil then return end
    assert(type(dx) == "number", "moveBy : param #1 must be a number type")
    assert(type(dy) == "number", "moveBy : param #2 must be a number type")

    self:setX(self:getX() + dx)
    self:setY(self:getY() + dy)
end

--=========
-- Rotation
--=========

--- Returns the rotation for the object.
---@return number rotation
function TObject:getRotation()
    return self.rotation or 0
end

--- Sets the rotation for the object.
---@param rotation number The rotation in radians for the object.
function TObject:setRotation(rotation)
    if not self.rotation then return end
    assert(type(rotation) == 'number', "setRotation : param #1 must be a number type")
    self.rotation = rotation
end

--- Rotates the object by the specified number of radians.
---@param rotation number The angle of rotation in radians to rotate by
function TObject:rotateBy(rotation)
    if not self.rotation then return end
    assert(type(rotation) == 'number', "rotateBy : param #1 must be a number type")
    self.rotation = self.rotation + rotation
end

--======
-- Scale
--======

--- Returns the scale factors for the x and y directions.
---@return number sx, number sy
function TObject:getScale()
    return self:getScaleX(), self:getScaleY()
end

--- Returns the scale factor for the x direction.
---@return number sx
function TObject:getScaleX()
    return self.sx or 1
end

--- Returns the scale factor for the y direction.
---@return number sy
function TObject:getScaleY()
    return self.sy or 1
end

--- Sets the scale factor for the x and y directions.
---@param sx number The scale factor for the x direction
---@param sy number The scale factor for the y direction
function TObject:setScale(sx, sy)
    if self.sx == nil then return end
    if self.sy == nil then return end
    assert(type(sx) == 'number', "setScale : param #1 must be a number type")
    assert(type(sy) == 'number', "setScale : param #2 must be a number type")
    self.sx = sx
    self.sy = sy
end

--- Sets the scale factor for the x direction.
---@param sx number The scale factor for the x direction
function TObject:setScaleX(sx)
    if self.sx == nil then return end
    assert(type(sx) == 'number', "setScaleX : param #1 must be a number type")
    self.sx = sx
end

--- Sets the scale factor for the y direction.
---@param sy number The scale factor for the y direction
function TObject:setScaleY(sy)
    if self.sy == nil then return end
    assert(type(sy) == 'number', "setScaleY : param #1 must be a number type")
    self.sy = sy
end

--- Scales the object by the specified amount.
---@param sx number The amount to scale the object in the x direction
---@param sy number The amount to scale the object in the y direction
function TObject:scaleBy(sx, sy)
    if self.sx == nil then return end
    if self.sy == nil then return end
    assert(type(sx) == 'number', "scaleBy : param #1 must be a number type")
    assert(type(sy) == 'number', "scaleBy : param #2 must be a number type")
    self.sx = self.sx + sx
    self.sy = self.sy + sy
end

--=======
-- Origin
--=======

--- Returns the object origin.
---@return number ox, number oy
function TObject:getOrigin()
    return self:getOriginX(), self:getOriginY()
end

--- Returns the object origin on the x-axis.
---@return number ox
function TObject:getOriginX()
    return self.ox or 0
end

--- Returns the object origin on the y-axis.
---@return number oy
function TObject:getOriginY()
    return self.oy or 0
end

--- Sets the object origin.
---@param ox number The origin point x-coordinate
---@param oy number The origin point y-coordinate
function TObject:setOrigin(ox, oy)
    if not self.ox then return end
    if not self.oy then return end
    assert(type(ox) == "number", "setOrigin : param #1 must be a number type")
    assert(type(oy) == "number", "setOrigin : param #2 must be a number type")
    self.ox = ox
    self.oy = oy
end

--- Sets the object origin on the x-axis.
---@param ox number The origin point x-coordinate
function TObject:setOriginX(ox)
    if not self.ox then return end
    assert(type(ox) == "number", "setOriginX : param #1 must be a number type")
    self.ox = ox
end

--- Sets the object origin on the y-axis.
---@param oy number The origin point y-coordinate
function TObject:setOriginY(oy)
    if not self.oy then return end
    assert(type(oy) == "number", "setOriginY : param #1 must be a number type")
    self.oy = oy
end

--========
-- Drawing
--========

--- Returns the coordinates necessary for the love.graphics.draw() method.
---@return number x, number y, number rotation, number scalex, number scaley, number ox, number oy
function TObject:getDrawCoords()
    return
        self:getX() + self:getOffsetX() - self:getOriginX(),
        self:getY() + self:getOffsetY() - self:getOriginY(),
        self:getRotation(),
        self:getScaleX(), self:getScaleY(),
        self:getOriginX(),
        self:getOriginY()
end

--===========
-- Dimensions
--===========

--- Returns the width and height of the map item.
---@return number width, number height
function TObject:getDimensions()
    return self:getWidth(), self:getHeight()
end

--- Returns the width of the map item.
---@return number width
function TObject:getWidth()
    return self.width or 0
end

--- Returns the height of the map item.
---@return number height
function TObject:getHeight()
    return self.height or 0
end

--- Returns the x, y, width and height of the object.
---@return number x, number y, number width, number height
function TObject:getRect()
    return self:getX() - self:getOriginX(), self:getY() - self:getOriginY(), self:getWidth(), self:getHeight()
end

--========
-- Offsets
--========

--- Returns the object offset.
function TObject:getOffsets()
    return self:getOffsetX(), self:getOffsetY()
end

--- Returns the offset of the map item along the x-axis.
---@return number offsetx
function TObject:getOffsetX()
    return self.offsetx or 0
end

--- Returns the offset of the map item along the y-axis.
---@return number offsety
function TObject:getOffsetY()
    return self.offsety or 0
end

--- Sets the offsets for the object.
---@param offsetx number The offset in the x-axis
---@param offsety number The offset in the y-axis
function TObject:setOffsets(offsetx, offsety)
    if self.offsetx == nil then return end
    if self.offsety == nil then return end
    assert(type(offsetx) == "number", "setOffsets : param #1 must be a number type")
    assert(type(offsety) == "number", "setOffsets : param #2 must be a number type")
    self.offsetx = offsetx
    self.offsety = offsety
end

--- Sets the offset for the map item in the x direction.
---@param offsetx number New offset for the map item in the x direction
function TObject:setOffsetX(offsetx)
    if not self.offsetx then return end
    assert(type(offsetx) == "number", "setOffsetX : param #1 must be a number type")
    self.offsetx = offsetx
end

--- Sets the offset for the map item in the y direction.
---@param offsety number New offset for the map item in the x direction
function TObject:setOffsetY(offsety)
    if not self.offsety then return end
    assert(type(offsety) == "number", "setOffsetY : param #1 must be a number type")
    self.offsety = offsety
end

--===========
-- Visibility
--===========

--- Returns true if the object is visible.
---@return boolean
function TObject:isVisible()
    if self.visible == nil then return true end
    return (self.visible == true)
end

--- Sets the visibility flag for the map item.
---@param visible boolean
function TObject:setVisibility(visible)
    if (self.visible == nil) or (visible == nil) then return end
    self.visible = (visible == true)
end

--- Returns the opacity of the map item.
---@return number opacity
function TObject:getOpacity()
    return self.opacity or 1
end

--- Sets the map item opacity.
---@param opacity number Normalized opacity value
function TObject:setOpacity(opacity)
    if not self.opacity then return end
    assert(type(opacity) == 'number', "setOpacity : param #1 must be a number type")
    self.opacity = utils.math.clamp(opacity, 0, 1)
end

--===========
-- Properties
--===========

--- Returns the property value for the provided key.
---@param key string The property key
---@return any
function TObject:getProperty(key)
    if self.properties == nil then return end
    return self.properties:get(key)
end

--- Sets a property for the provided key.
---@param key string The property key
---@param value any The value to store for the property
function TObject:setProperty(key, value)
    if self.properties == nil then return end
    self.properties:set(key, value)
end

--- Returns the number of properties for the object.
---@return integer numprops
function TObject:getNumProperties()
    if self.properties == nil then return 0 end
    return self.properties:getNumProperties()
end

--- Returns true if the object contains a property with the key value.
---@param key string The property key
---@return boolean
function TObject:hasPropertyKey(key)
    if self.properties == nil then return false end
    return self.properties:hasKey(key)
end

return TObject