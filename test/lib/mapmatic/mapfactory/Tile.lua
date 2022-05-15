local lib = (...):gsub("mapfactory.Tile$", '')
local cwd = (...):gsub("%.Tile$", '') .. '.'

local Class         = require(lib .. "class")
local TObject       = require(cwd .. "TObject")
local MapObject     = require(cwd .. 'MapObject')
local MapProperties = require(cwd .. 'MapProperties')
local TileAnimation = require(cwd .. 'TileAnimation')

local Tile    = Class{__name='Tile', __includes=TObject}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Sets up the information for the new tile.
---@param tile table The current tile
---@param tileset table The tileset the tile belongs to
---@param gid integer The global ID of the tile
local function _setup_tile(tile, tileset, gid)
    local id        = gid - tileset:getFirstGid()
    local tileimage = tile:getImage() or tileset:getImage()

    tile.id           = id
    tile.gid          = gid
    tile.tileset      = tileset
    tile.width        = tile:getWidth() or tileset:getTileWidth()
    tile.height       = tile:getHeight() or tileset:getTileHeight()
    tile.image        = tileimage
    tile.sx           = 1
    tile.sy           = 1
    tile.rotation     = 0
    tile.ox           = 0
    tile.oy           = 0
    tile.properties   = MapProperties(tile.properties or {}, tileset)

    if tile.animation then
        setmetatable(tile.animation, TileAnimation)
        tile.animation:init(tile)
    end
end

--- Builds a new Quad for tiles that belong to tilesets.
---@param tile table The current tile
---@param row integer The row the tile is located in the tileset
---@param col integer The column the tile is located in the tileset
local function _build_atlas_quad(tile, row, col)
    local tileset = tile:getTileSet()
    if not tileset:isAtlas() then return end

    local tileW = tile:getWidth() or tileset:getTileWidth()
    local tileH = tile:getHeight() or tileset:getTileHeight()

    local imageW  = tileset:getImageWidth()
    local imageH  = tileset:getImageHeight()
    local margin  = tileset:getMargin()
    local spacing = tileset:getSpacing()

    local quadX = (col - 1) * tileW + margin + (col - 1) * spacing
    local quadY = (row - 1) * tileH + margin + (row - 1) * spacing
    tile.quad = love.graphics.newQuad(quadX, quadY, tileW, tileH, imageW, imageH)
end

--- Build any objects that exist in the tile objectGroup.
---@param tile table The current tile
---@param map table The current map
local function _build_tile_objects(tile, map)
    if not tile.objectGroup then return end

    -- TODO: Create ObjectGroup class
    for _, object in ipairs(tile.objectGroup.objects) do
        object.objecttype = object.type
        object.type = nil
        setmetatable(object, MapObject)
        object:init(tile, map)

        map.objects.tiles = map.objects.tiles or {}
        map.objects.tiles[object:getId()] = object
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Builds a global tile object that includes extra information not found in the tileset.
---@param map table The current map
---@param tileset table The tileset the tile belongs to
---@param row integer The row the tile is located in the tileset
---@param col integer The column the tile is located in the tileset
---@param gid integer The global ID of the tile
function Tile:init(map, tileset, row, col, gid)
    _setup_tile(self, tileset, gid)
    _build_atlas_quad(self, row, col)
    _build_tile_objects(self, map)
end

--- Returns the global ID for the tile.
---@return integer gid
function Tile:getGid()
    return self.gid
end

--- Returns the associated tileset the tile belongs to.
---@return table tileset
function Tile:getTileSet()
    return self.tileset
end

--- Shortcut method to get the tileset index.
---@return integer index
function Tile:getTileSetIndex()
    return self:getTileSet():getIndex()
end

--- Shortcut method that returns true if the tile belongs to a tileset that is an atlas
--- and false if it belongs to a tile collection.
---@return boolean
function Tile:isAtlas()
    return self:getTileSet():isAtlas()
end

--- Return the image for the tile.
---@return userdata image
function Tile:getImage()
    return self.image
end

--- Returns the quad for the tile image (tile sets only), or nil if the tile belongs to a tile collection.
---@return userdata quad
function Tile:getQuad()
    if not self:isAtlas() then return end
    return self.quad
end

--- Shortcut method that returns the image type (atlas or collection) for the tileset the tile belongs to.
---@return string imagetype
function Tile:getImageType()
    return self:getTileSet():getImageType()
end

--- Returns the width of the tile.
---@return number width
function Tile:getWidth()
    return self:isAtlas() and self:getTileSet():getTileWidth() or self:getImage():getWidth()
end

--- Returns the height of the tile.
---@return number height
function Tile:getHeight()
    return self:isAtlas() and self:getTileSet():getTileHeight() or self:getImage():getHeight()
end

--- Returns the x and y offsets for the tile.
---@return table offsets
function Tile:getOffsets()
    return self:getTileSet():getOffsets()
end

--- Returns the x offset for the tile.
---@return integer xoffset
function Tile:getOffsetX()
    return self:getTileSet():getOffsetX()
end

--- Returns the y offset for the tile.
---@return integer yoffset
function Tile:getOffsetY()
    return self:getTileSet():getOffsetY()
end

--- Returns true if the tile contains an animation sequence.
---@return boolean
function Tile:hasAnimation()
    return not (self.animation == nil)
end

--- Returns the animation object for the tile.
---@return table animation
function Tile:getAnimation()
    if not self:hasAnimation() then return end
    return self.animation
end

--- Return true if the tile has the object specified by the object id parameter.
---@param objectid integer|string The index or name of the tile object to locate.
---@return boolean
function Tile:hasObject(objectid)
    return pcall(self.getObject, self, objectid)
end

--- Returns true if the tile contains at least one object.
---@return boolean
function Tile:hasObjects()
    return not (self.objectGroup == nil)
end

--- Returns a tile object either by its id or by its name.
---@param objectid integer|string The index or name of the tile object to locate.
---@return table object
function Tile:getObject(objectid)
    assert(self.objectGroup, "getObject: specified tile does not have any object groups associated : id="..tostring(objectid))

    local type_id = type(objectid)
    assert((type_id == 'string') or (type_id == 'number'),
        'getObject : objectid must be either a string name or the numerical id : id=' .. tostring(objectid))

    local tileobject
    if (type_id == 'string') then
        for _, object in pairs(self.objectGroup.objects) do
            if object.name == objectid then tileobject = object; break end
        end
    else
        for _, object in pairs(self.objectGroup.objects) do
            if object.id == objectid then tileobject = object; break end
        end
    end

    assert(tileobject, "getObject : object with specified object id does not exist on object layer : id=" .. tostring(objectid))
    return tileobject
end

--- Returns the reference to the table containing the list of objects for the tile.
---@return table objects
function Tile:getObjects()
    if not self:hasObjects() then return {} end
    return self.objectGroup.objects
end

return Tile