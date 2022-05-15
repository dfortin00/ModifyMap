local lib = (...):gsub("mapfactory.MapObject$", '')
local cwd = (...):gsub("%.MapObject$", '') .. '.'

local utils   = require(lib .. "utils")
local Class   = require(lib .. "class")
local TObject = require(cwd .. "TObject")

local maputils      = require(cwd .. "maputils")
local MapProperties = require(cwd .. "MapProperties")

local TILE_OBJECT = "tileobject"

local MapObject = Class{__name="MapObject", __includes=TObject}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Sets up a rectangular object. Note: this does not set up a tile object which can also be a "rectangle".
---@param map table The current map
---@param object table The object table from the exported map file
---@param x number The x-coordinate of the object relative to the map
---@param y number The y-coordinate of the object relative to the map
---@param w number The width of the object
---@param h number The height of the object
local function _setup_rectangle(map, object, x, y, w, h)
    local cos = math.cos(object.rotation)
    local sin = math.sin(object.rotation)
    local vertices = {
        { x = x,     y = y     },
        { x = x + w, y = y     },
        { x = x + w, y = y + h },
        { x = x,     y = y + h },
    }

    object.rectangle = {}
    for _, vertex in ipairs(vertices) do
        if not (object:getRotation() == 0) then
            maputils.rotateVertex(map, vertex, x, y, cos, sin)
        end
        table.insert(object.rectangle, {x = vertex.x, y = vertex.y})
    end
end

--- Sets up an elliptical object.
---@param map table The current map
---@param object table The object table from the exported map file
---@param x number The x-coordinate of the center of the object relative to the map
---@param y number The y-coordinate of the center of the object relative to the map
---@param w number The length of the ellipse horizontal diameter
---@param h number The height of the ellipse vertical diameter
local function _setup_ellipse(map, object, x, y, w, h)
    local cos = math.cos(object.rotation)
    local sin = math.sin(object.rotation)
    local vertices = maputils.convertEllipseToPolygon(x, y, w, h)

    object.ellipse = {}
    for _, vertex in ipairs(vertices) do
        if not (object:getRotation() == 0) then
            maputils.rotateVertex(map, vertex, x, y, cos, sin)
        end
        table.insert(object.ellipse, {x = vertex.x, y = vertex.y})
    end
end

--- Sets up a polygon or polygon shape object.
---@param map table The current map
---@param object table The object table from the exported map file
---@param x number The x-coordinate of the first vertex point in the list
---@param y number The y-coordinate of the first vertext point in the list
local function _setup_poly_shape(map, object, x, y)
    local cos = math.cos(object.rotation)
    local sin = math.sin(object.rotation)

    local polytable = (object:getShape() == "polygon") and object.polygon or object.polyline

    for _, vertex in ipairs(polytable) do
        vertex.x = vertex.x + x
        vertex.y = vertex.y + y

        maputils.rotateVertex(map, vertex, x, y, cos, sin)
    end
end

--- Sets the object coordinates to the correct screen coordinates.
---@param object table The object table from the exported map file
---@param owner table The owner of the object (ObjectLayer|Tile)
---@param map table The current map
local function _set_object_coordinates(object, owner, map)
    local x = (owner and owner:getOffsetX() or 0) + object:getX()
    local y = (owner and owner:getOffsetY() or 0) + object:getY()
    local w = object:getWidth()
    local h = object:getHeight()

    -- TODO: Move object shapes into their own class modules??

    -- Note: Rectangle shapes with a gid are tile objects.
    if object:getShape() == "rectangle" and not object:getGid() then
        _setup_rectangle(map, object, x, y, w, h)
    elseif object:getShape() == "ellipse" then
        _setup_ellipse(map, object, x, y, w, h)
    elseif object:getShape() == "polygon" or object:getShape() == "polyline" then
        _setup_poly_shape(map, object, x, y)
    end
end

--- Compensate for any scale or rotation shift. Note: Tile object coordinates in Tiled are taken
--- from the bottom left corner, but tile coordinates for this library need to use the top left corner.
---@param object table The current object
---@param tile table The tile used by the object
---@param tileX number The x-coordinate of the tile object
---@param tileY number The y-coordinate of the tile object
---@param tileR number The rotation in radians for the tile object
---@return number originX, number originY
local function _compensate_shift(object, tile, tileX, tileY, tileR)
    local ox = 0
    local oy = tile:getHeight()

    if tile.sx == -1 then
        tileX = tileX + object:getWidth()
        if not (tileR == 0) then
            tileX = tileX - object:getWidth()
            ox = ox + tile:getWidth()
        end
    end

    if tile.sy == -1 then
        tileY = tileY - object:getHeight()
        if not (tileR == 0) then
            tileY = tileY + object:getHeight()
            oy = oy - tile:getHeight()
        end
    end

    return ox, oy, tileX, tileY
end

--- Builds the tile object and sets up any tile animations.
---@param object table The current tile object
---@param owner table The owner of the tile object (ObjectLayer|Tile)
---@param map table The current map
local function _build_tile_object(object, owner, map)
    local tile = map:getTile(object:getGid()) or maputils.buildTransformedTile(map, object:getGid())

    local tileX = object:getX() + tile:getOffsetX()
    local tileY = object:getY() + tile:getOffsetY()

    local sx = object:getWidth() / tile:getWidth() * utils.math.sign(tile:getScaleX())
    local sy = object:getHeight() / tile:getHeight() * utils.math.sign(tile:getScaleY())

    local tileR = object:getRotation() + tile:getRotation()

    local ox, oy
    ox, oy, tileX, tileY = _compensate_shift(object, tile, tileX, tileY, tileR)

    object.shape    = TILE_OBJECT
    object.tile     = tile
    object.x        = tileX
    object.y        = tileY + tile:getHeight()
    object.rotation = tileR
    object.sx       = sx
    object.sy       = sy
    object.ox       = ox
    object.oy       = oy

    if tile.animation and utils.class.typeOf(owner, "ObjectLayer") then
        object.animation = utils.table.copy(tile:getAnimation())
        map.animations[owner:getLayerPath()] = map.animations[owner:getLayerPath()] or {}
        table.insert(map.animations[owner:getLayerPath()], object)
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Sets up object coordinates and loads tile objects.
---@param owner table The owner of the object (either a Tile or ObjectLayer object)
---@param map table The current map
function MapObject:init(owner, map)
    self.owner    = owner
    self.name     = self.name or ""
    self.rotation = math.rad(self.rotation)

    _set_object_coordinates(self, owner, map)

    if self:getShape() == "rectangle" and self:getGid() then
        _build_tile_object(self, owner, map)
    end

    self.properties = MapProperties(self, owner)
end

--- Returns the tile object GID, or nil if object is not a tile.
---@return number|nil gid
function MapObject:getGid()
    return self.gid
end

--- Returns the owner for this object.
---@return table owner
function MapObject:getOwner()
    return self.owner
end

-- TODO: This should be put inside the TileShape class when it is created.
--- Retrieve the tile for a tile object.
---@return table tile
function MapObject:getTile()
    if not (self:getShape() == TILE_OBJECT) then return end
    return self.tile
end

--- Returns the shape type.
---@return string shape
function MapObject:getShape()
    return self.shape
end

--- Returns the table containing the shape vertices. Tile objects return an empty table.
---@return table vertices
function MapObject:getVertices()
    if self:getShape() == TILE_OBJECT then return {} end
    return self.polygon or self.polyline or self.ellipse or self.rectangle
end

--- Returns which type the object represents.
---@return string objectType
function MapObject:getObjectType()
    return self.objecttype
end

--- Move the object to the specified coordinates.
---@param x number X-coordinate in pixels
---@param y number Y-coordinate in pixels
function MapObject:setPosition(x, y)
    assert(type(x) == "number", "setPosition : param #1 must be a number type")
    assert(type(y) == "number", "setPosition : param #2 must be a number type")

    if not (self:getShape() == TILE_OBJECT) then
        local vertices = self:getVertices()
        for _, vertex in ipairs(vertices) do
            vertex.x = vertex.x - self:getX() + x
            vertex.y = vertex.y - self:getY() + y
        end
    end

    self.x = x
    self.y = y
end

--- Moves the object to the specified coordinate in the x direction.
---@param x number X-coordinate in pixels
function MapObject:setX(x)
    assert(type(x) == "number", "setX : param #1 must be a number type")
    if not (self:getShape() == TILE_OBJECT) then
        local vertices = self:getVertices()
        for _, vertex in ipairs(vertices) do
            vertex.x = vertex.x - self:getX() + x
        end
    end
    self.x = x
end

--- Moves the object to the specified coordinate in the y direction.
---@param y number Y-coordinate in pixels
function MapObject:setY(y)
    assert(type(y) == "number", "setY : param #1 must be a number type")
    if not (self:getShape() == TILE_OBJECT) then
        local vertices = self:getVertices()
        for _, vertex in ipairs(vertices) do
            vertex.y = vertex.y - self:getY() + y
        end
    end
    self.y = y
end

--- Move the object by the number of specified pixels in the x and y direction.
---@param x number Number of pixels to move in the x-axis
---@param y number Number of pixels to move in the y-axis
function MapObject:moveBy(x, y)
    assert(type(x) == "number", "moveBy : param #1 must be a number type")
    assert(type(y) == "number", "moveBy : param #2 must be a number type")

    if not (self:getShape() == TILE_OBJECT) then
        local vertices = self:getVertices()
        for _, vertex in ipairs(vertices) do
            vertex.x = vertex.x + x
            vertex.y = vertex.y + y
        end
    end

    self.x = self.x + x
    self.y = self.y + y
end

--TODO: Change rotation of map object.
--- Sets the rotation for the object.
---@param rotation number The new rotation for the object (in radians)
function MapObject:setRotation(rotation)
    error("setRotation : Method not yet implemented")
end

--- Rotates the object by the specified amount in radians.
---@param rotation number The number of radians to rotate the object
function MapObject:rotateBy(rotation)
    error("rotateBy : Method not yet implemented")
end

--- Scales the map object in both the x and y directions.
---@param sx number The scale factor for the x axis
---@param sy number The scale factor for the y axis
function MapObject:setScale(sx, sy)
    error("setScale : Method not yet implemented")
end

--- Scales the map object in the x direction.
---@param sx number The scale factor for the x axis
function MapObject:setScaleX(sx)
    error("setScaleX : Method not yet implemented")
end

--- Scales the map object in the y direction.
---@param sy number The scale factor for the y axis
function MapObject:setScaleY(sy)
    error("setScaleY : Method not yet implemented")
end

--- Scales the map object by the specified amount in both the x and y directions.
---@param sx number The amount to scale in the x direction
---@param sy number The amount to scale in the y direction
function MapObject:scaleBy(sx, sy)
    error("scaleBy : Method not yet implemented")
end

--- Determines if the object is visible on screen.
---@return boolean
function MapObject:isVisible()
    local owner = self:getOwner()
    if (owner:type() == "ObjectLayer") and not owner:isVisible() then return false end
    return (self.visible == true)
end

--TODO: Move this into TileShape class when it is created.
--- Determines if the tile object has an animation sequence associated with it.
---@return boolean
function MapObject:hasAnimation()
    if not (self:getShape() == TILE_OBJECT) then return false end
    return not (self.animation == nil)
end

--TODO: Move this into TileShape class when it is created.
--- Returns the animation for a tile object if it has one.
---@return table|nil animation
function MapObject:getAnimation()
    if not self:hasAnimation() then return end
    return self.animation
end

return MapObject