local lib = (...):gsub("mapfactory.TileInstance$", '')
local cwd = (...):gsub("%.TileInstance$", '') .. '.'

local utils    = require(lib .. "utils")
local Class    = require(lib .. "class")
local TObject  = require(cwd .. "TObject")
local maputils = require(cwd .. 'maputils')

local TileInstance = Class{__name='TileInstance', __includes=TObject}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Add the tile instance to the tile layer sprite batch.
---@param instance table The current tile instance
local function _update_batch(instance)
    if not instance:usesBatch() then return end

    local tile = instance:getTile()
    if instance:isAtlas() then
        instance.batch:set(instance:getBatchId(), tile:getQuad(), instance:getDrawCoords())
    else
        instance.batch:set(instance:getBatchId(), instance:getDrawCoords())
    end
end

--- Compensation for scale/rotation shift on orthogonal maps.
---@param tile table The tile associated with the tile instance
---@param tileX number The x-coordinate of the tile instance
---@param tileY number The y-coordinate of the tile instance
---@param tileW number The width of the tile instance
---@param tileH number The height of the tile instance
---@return number tilex, number tiley
local function _compensate_shift(tile, tileX, tileY, tileW, tileH)
    local compx = 0
    local compy = 0

    if tile.sx < 0 then compx = tileW end
    if tile.sy < 0 then compy = tileH end

    if tile.rotation > 0 then
        tileX = tileX + tileH - compy
        tileY = tileY + tileH + compx - tileW
    elseif tile.rotation < 0 then
        tileX = tileX + compy
        tileY = tileY - compy + tileH
    else
        tileX = tileX + compx
        tileY = tileY + compy
    end

    return tileX, tileY
end

--- Retrieves the tile coordinates for orthogonal maps.
---@param map table The current map
---@param tile table The tile associated with the tile instance
---@param col integer The column the tile instance is located on the map
---@param row integer The row the tile instance is located on the map
---@return number tilex, number tiley
local function _get_orth_tile_position(map, tile, col, row)
    local tileW   = map:getTileWidth()
    local tileH   = map:getTileHeight()
    local tileset = tile:getTileSet()

    local tileX, tileY

    tileX = (col - 1) * tileW

    if tile:isAtlas() then
        tileY = row * tileH - tileset:getTileHeight()
    else
        tileY = row * tileH - tile:getHeight()
        tileH = tile:getHeight()
    end

    return _compensate_shift(tile, tileX, tileY, tileW, tileH)
end

--- Retrieves the tile coordinates for isometric maps.
---@param map table The current map
---@param layer table The tile layer that owns the tile instance
---@param tile table The tile associated with the tile instance
---@param col integer The column the tile instance is located on the map
---@param row integer The row the tile instance is located on the map
---@return number tileX, number tileY
local function _get_iso_tile_position(map, layer, tile, col, row)
    local tileW = map:getTileWidth()
    local tileH = map:getTileHeight()
    local tileX, tileY

    tileX = (col - row) * (tileW * 0.5) + layer:getWidth() * tileW * 0.5 - tileW * 0.5
    tileY = (col + row - 2) * (tileH * 0.5)
    tileY = ((tile:getHeight() * 0.5) == tileH) and tileY or (tileY - tile:getHeight() * 0.5)

    return tileX, tileY
end

--- Retrieves the tile coordinates for hexagonal maps.
---@param map table The current map
---@param tile table The tile associated with the tile instance
---@param col integer The column the tile instance is located on the map
---@param row integer The row the tile instance is located on the map---@return number
---@return number tileX, number tileY
local function _get_hex_tile_position(map, tile, col, row)
    local tileW = map:getTileWidth()
    local tileH = map:getTileHeight()
    local tileX, tileY

    local sidelength = map.hexsidelength or 0
    local oddStagger = (map.staggerindex == 'odd')

    if map.staggeraxis == 'y' then
        local isEven = (row % 2 == 0)
        local test = (oddStagger and isEven) or (not oddStagger and not isEven)
        local widthoffset = test and (tileW * 0.5) or 0
        local rowH = tileH - (tileH - sidelength) * 0.5

        tileX = (col - 1) * tileW + widthoffset
        tileY = (row - 1) * rowH + tileH - tile:getHeight()
    else
        local isEven = (col % 2 == 0)
        local test = (oddStagger and isEven) or (not oddStagger and not isEven)
        local heightoffset = test and (tileH * 0.5) or 0
        local colW = tileW - (tileW - sidelength) * 0.5

        tileX = (col - 1) * colW
        tileY = (row - 1) * tileH + heightoffset
    end

    return tileX, tileY
end

--- Retrieves the tile pixel coordinates based on the map type.
---@param layer table The current tile layer
---@param map table The current map
---@param tile table The tile associated with the tile instance
---@param col integer The column the tile instance is located on the map
---@param row integer The row the tile instance is located on the map
---@return number tilex, number tiley
local function _get_tile_position(layer, map, tile, col, row)
    if map:getOrientation() == 'orthogonal' then
        return _get_orth_tile_position(map, tile, col, row)
    elseif map:getOrientation() == 'isometric' then
        return _get_iso_tile_position(map, layer, tile, col, row)
    elseif map:getOrientation() == 'hexagonal' then
        return _get_hex_tile_position(map, tile, col, row)
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Create and initialize an instance of a global tile inside a tile layer.
---@param map table The current map
---@param layer table The tile layer that owns this instance
---@param col integer The column the tile instance is located on the map
---@param row integer The row the tile instance is located on the map
---@param gid integer The global ID of the tile
---@param chunk table Used when the map is infinite
function TileInstance:init(map, layer, col, row, gid, chunk)
    local tile = map.tiles[gid] or maputils.buildTransformedTile(map, gid)

    local offsetcol = chunk and chunk.x or 0
    local offsetrow = chunk and chunk.y or 0

    local tileX, tileY = _get_tile_position(layer, map, tile, col + offsetcol, row + offsetrow)

    self.owner    = layer
    self.tile     = tile
    self.x        = tileX
    self.y        = tileY

    -- The rotation, scale and origin cannot be set for a tile instance in Tiled, so start with some defaults.
    self.rotation = 0
    self.sx       = 1
    self.sy       = 1
    self.ox       = 0
    self.oy       = 0

    if tile.animation then
        self.animation = utils.table.copy(tile.animation)
        map.animations[layer:getLayerPath()] = map.animations[layer:getLayerPath()] or {}
        table.insert(map.animations[layer:getLayerPath()], self)
    end
end

--- Returns the tile layer that owns this instance.
---@return table owner
function TileInstance:getOwner()
    return self.owner
end

--- Returns the global tile this instance was derived from.
---@return table tile
function TileInstance:getTile()
    return self.tile
end

--- Returns the tileset that contains the tile for the instance.
---@return table tileset
function TileInstance:getTileSet()
    return self:getTile():getTileSet()
end

--- Returns the id of the tile.
---@return integer id
function TileInstance:getId()
    return self:getTile():getId()
end

--- Returns the global ID of the tile.
---@return integer gid
function TileInstance:getGid()
    return self:getTile():getGid()
end

--- Sets the x,y coordinate of the tile instance relative to the top left corner of the map.
---@param px number The new x-coordinate of the tile instance
---@param py number The new y-coordinate of the tile instance
function TileInstance:setPosition(px, py)
    TObject.setPosition(self, px, py)
    _update_batch(self)
end

--- Moves the tile by the specified amount in the x and y axes.
---@param dx number The amount to move the tile in the x direction.
---@param dy number The amount to move the tile in the y direction.
function TileInstance:moveBy(dx, dy)
    TObject.moveBy(self, dx, dy)
    _update_batch(self)
end

--- Sets the rotation for the tile instance.
---@param rotation number The rotation in radians
function TileInstance:setRotation(rotation)
    TObject.setRotation(self, rotation)
    _update_batch(self)
end

--- Rotates the tile instance by the specified amount in radians.
---@param rotation number The number of radians to rotate the tile instance
function TileInstance:rotateBy(rotation)
    TObject.rotateBy(self, rotation)
    _update_batch(self)
end

--- Sets the scaling factor used to draw the tile instance.
---@param sx any
---@param sy any
function TileInstance:setScale(sx, sy)
    TObject.setScale(self, sx, sy)
    _update_batch(self)
end

--- Sets the scale factor in the x axis.
---@param sx number Scale factor
function TileInstance:setScaleX(sx)
    TObject.setScaleX(self, sx)
    _update_batch(self)
end

--- Sets the scale factor in the y axis.
---@param sy number Scale factor
function TileInstance:setScaleY(sy)
    TObject.setScaleY(self, sy)
    _update_batch(self)
end

--- Scales the tile instance by the specified scaling factors.
---@param sx number The scale factor for the x direction
---@param sy number The scale factor for the y direction
function TileInstance:scaleBy(sx, sy)
    TObject.scaleBy(self, sx, sy)
    _update_batch(self)
end

--- Sets the origin point used when drawing the tile instance.
---@param ox number The new x-coordinate for the origin
---@param oy number The new y-coordinate for the origin
function TileInstance:setOrigin(ox, oy)
    TObject.setOrigin(self, ox, oy)
    _update_batch(self)
end

--- Sets the x-coordinate for the origin point of the tile.
---@param ox number The x-coordinate of the origin point
function TileInstance:setOriginX(ox)
    TObject.setOriginX(self, ox)
    _update_batch(self)
end

--- Sets the y-coordinate of the origin point of the tile.
---@param oy number The y-coordinate of the origin point
function TileInstance:setOriginY(oy)
    TObject.setOriginY(self, oy)
    _update_batch(self)
end

--- Returns the width and height of the tile.
---@return number width, number height
function TileInstance:getDimensions()
    return self:getTile():getWidth(), self:getTile():getHeight()
end

--- Returns the width of the tile.
---@return number width
function TileInstance:getWidth()
    return self:getTile():getWidth()
end

--- Returns the height of the tile.
---@return number height
function TileInstance:getHeight()
    return self:getTile():getHeight()
end

-- NOTE: Setting offsets for a tile instance can only be done at the tileset level.

--- Returns the offset for the tile instance in the x direction.
---@return number offsetx
function TileInstance:getOffsetX()
    return self:getTileSet():getOffsetX()
end

--- Returns the offset for the tile instance in the y direction.
---@return number offsetx
function TileInstance:getOffsetY()
    return self:getTileSet():getOffsetY()
end

--- Returns the tile image.
---@return userdata image
function TileInstance:getImage()
    return self:getTile():getImage()
end

--- Returns the quad if the tile belongs to a tileset.
---@return userdata quad
function TileInstance:getQuad()
    return self:getTile():getQuad()
end

--- Returns true if the tile is drawn with a SpriteBatch, or false if it is drawn with a layer renderer.
---@return boolean
function TileInstance:usesBatch()
    return not (self.batch == nil)
end

--- Returns the SpriteBatch that contains the tile. Note, this will return nil if the tile layer
--- has batch drawing disabled.
---@return userdata spritebatch
function TileInstance:getBatch()
    return self.batch
end

--- Returns the id for the tile inside the SpriteBatch. Note, this will return nil if the tile
--- layer has batch drawing disabled.
---@return integer batchid
function TileInstance:getBatchId()
    return self.batchid
end

--- Returns true if the tile is part of a tileset, or false if it is part of a tile collection.
---@return boolean
function TileInstance:isAtlas()
    return self:getTile():isAtlas()
end

--- Returns 'atlas' if the tile is part of a tileset, or 'collection' if part of a tile collection.
---@return string imagetype
function TileInstance:getImageType()
    return self:getTile():getImageType()
end

---  Return true if the tile has the object specified by the object id parameter.
---@param objectid integer|string The index or name of the tile object to locate.
---@return table object
function TileInstance:hasObject(objectid)
    return self:getTile():hasObject(objectid)
end

--- Returns true if the tile contains at least one object.
---@return boolean
function TileInstance:hasObjects()
    return self:getTile():hasObjects()
end

--- Returns a tile object either by its id or by its name.
---@param objectid integer|string The index or name of the tile object to locate.
---@return table object
function TileInstance:getObject(objectid)
    return self:getTile():getObject(objectid)
end

--- Returns the table containing the list of all tile objects.
---@return table objects
function TileInstance:getObjects()
    return self:getTile():getObjects()
end

--- Returns true if the tile has an animation associated with it.
---@return boolean
function TileInstance:hasAnimation()
    return not (self.animation == nil)
end

--- Returns the tile animation object if the tile instance is animated.
---@return table tileanimation
function TileInstance:getAnimation()
    return self.animation
end

return TileInstance