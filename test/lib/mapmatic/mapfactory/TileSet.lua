local lib = (...):gsub("mapfactory.TileSet$", '')
local cwd = (...):gsub("%.TileSet$", '') .. '.'

local utils         = require(lib .. "utils")
local Class         = require(lib .. "class")
local maputils      = require(cwd .. 'maputils')
local Tile          = require(cwd .. 'Tile')
local MapProperties = require(cwd .. 'MapProperties')

local TileSet = Class{__name='TileSet'}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Loads a tile set image either from a file, or from the cache if previously loaded.
---@param owner table The tileset that owns the image reference
---@param map table The current map
---@param path string The path location to the exported Lua map file
local function _load_cache_image(owner, map, path)
    local normpath = utils.string.normalizePath(path .. owner.image)
    if not map:getFactory():getCacheItem(normpath) then
        maputils.loadImage(owner, normpath)
        maputils.cacheImage(map:getFactory():getCache(), normpath, owner.image)
    else
        owner.image = map:getFactory():getCacheItem(normpath)
    end
end

--- Loads images for tileset atlases and tile collections.
---@param tileset table The current tileset
---@param map table The current map
---@param path string The path location to the exported Lua map file
local function _load_tileset_images(tileset, map, path)
    tileset.imagetype = tileset.image and 'atlas' or 'collection'
    if tileset.image then
        _load_cache_image(tileset, map, path)
    else
        for _, tile in ipairs(tileset.tiles) do
            _load_cache_image(tile, map, path)
        end
    end
end

--- Tile collections can have gaps in tile ids if images are added/removed from the tileset editor in Tiled.
---@param tileset table The current tileset
---@param gid integer The current GID count
---@return integer gid
local function _next_gid(tileset, gid)
    if tileset:isAtlas() then return gid end

    for _, tile in ipairs(tileset.tiles) do
        local nextid = tileset:getFirstGid() + tile.id
        if nextid >= gid then return nextid end
    end

    return gid
end

--- Scans tileset for tile data, or creates a new tile if no data exists.
---@param map table The current map
---@param tileset table The current tileset
---@param row integer The current row of the tile in the tileset
---@param col integer The current row of the tile in the tileset (set to 1 for tile collections)
---@param gid integer The current GID count
---@return table tile
local function _new_tile(map, tileset, row, col, gid)
    local firstgid = tileset.firstgid

    for _, tile in ipairs(tileset.tiles) do
        if (tile.id + firstgid) == gid then
            setmetatable(tile, Tile)
            tile:init(map, tileset, row, col, gid)
            return tile
        end
    end

    -- No matching tiles inside the tileset, so create one from scratch.
    return Tile(map, tileset, row, col, gid)
end

--- Create definitions for each tile whether it is being used or not.
---@param tileset table The current tileset
---@param map table The current map
local function _build_tile_list(tileset, map)
    local gid      = tileset:getFirstGid()
    local tilecols = tileset:getNumCols()
    local tilerows = tileset:getNumRows()
    local tilemap  = {}

    for row = 1, tilerows do
        for col = 1, tilecols do
            gid = _next_gid(tileset, gid)
            local tile = _new_tile(map, tileset, row, col, gid)

            tilemap[gid]   = tile
            map.tiles[gid] = tile

            gid = gid + 1
        end
    end

    tileset.tiles = tilemap
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Initializes the tileset and builds the global tile objects.
---@param map table The current map
---@param path string The path location of the exported Lua map file
---@param index integer The index of the tileset in the map lookup table
function TileSet:init(map, path, index)
    self.index = index
    self.properties = MapProperties(self, map)

    _load_tileset_images(self, map, path)
    _build_tile_list(self, map)
end

--- Returns the name of the tileset.
---@return string name
function TileSet:getName()
    return self.name
end

--- Returns the first GID index for the tileset.
---@return integer firstgid
function TileSet:getFirstGid()
    return self.firstgid
end

--- Returns the index the tileset appears in the exported Lua map file.
---@return integer index
function TileSet:getIndex()
    return self.index
end

--- Returns a tile from its GID, or nil if the tile does not belong to the tileset.
---@param gid integer The GID of the tile to lookup
---@return table|nil tile
function TileSet:getTile(gid)
    return self.tiles[gid]
end

--- Returns the table containing the list of tiles. Note: The table may have gaps if the
--- tileset is a collection.
---@return any
function TileSet:getTiles()
    return self.tiles
end

--- Returns the width of the tiles belonging to the tileset.
---@return integer tilewidth
function TileSet:getTileWidth()
    return self.tilewidth
end

--- Returns the height of the tiles belonging to the tileset.
---@return integer tileheight
function TileSet:getTileHeight()
    return self.tileheight
end

--- Returns the number of rows in the tileset  (return 1 for tile collections).
---@return integer rows
function TileSet:getNumRows()
    return (self:getTileCount() / self:getNumCols())
end

--- Returns either the number of columns in the tileset, or 1 if the tileset is a tile collection.
---@return integer cols
function TileSet:getNumCols()
    return self:isAtlas() and self.columns or 1
end

--- Returns the number of tiles contains within the tileset.
---@return integer tilecount
function TileSet:getTileCount()
    return self.tilecount
end

--- Returns true if tileset and false if tile collection.
---@return boolean
function TileSet:isAtlas()
    return (self:getImageType() == 'atlas')
end

--- Returns the image used by the tileset, or nil if the tileset is a tile collection.
---@return userdata image
function TileSet:getImage()
    return self.image
end

--- Returns the image type for the tileset.
---@return string imagetype
function TileSet:getImageType()
    return self.imagetype
end

--- Returns the dimensions of the image for tilesets.
---@return number imagewidth, number imageheight
function TileSet:getImageDimensions()
    return self:getImageWidth(), self:getImageHeight()
end

--- Returns the width of the image for a tileset.
---@return number imagewidth
function TileSet:getImageWidth()
    return self.imagewidth
end

--- Returns the height of the image for a tileset.
---@return number imageheight
function TileSet:getImageHeight()
    return self.imageheight
end

--- Returns the margins used by the tileset image.
---@return number margin
function TileSet:getMargin()
    return self.margin
end

--- Returns the spacing between tile images inside a tileset.
---@return number spacing
function TileSet:getSpacing()
    return self.spacing
end

--- Returns the offset each tile will be drawn relative to the top left corner of the map.
---@return number offsetx, number offsety
function TileSet:getOffsets()
    return self:getOffsetX(), self:getOffsetY()
end

--- Returns the tile offset in the x direction.
---@return number offsetx
function TileSet:getOffsetX()
    if not self.tileoffset then return 0 end
    return (self.tileoffset.x or 0)
end

--- Returns the tile offset in the y direction.
---@return number offsety
function TileSet:getOffsetY()
    if not self.tileoffset then return 0 end
    return (self.tileoffset.y or 0)
end

function TileSet:setOffsets(offsetx, offsety)
    assert(type(offsetx) == 'number', "setOffsets : param #1 must be a number type")
    assert(type(offsety) == 'number', "setOffsets : param #2 must be a number type")
    self.tileoffset = self.tileoffset or {}
    self.tileoffset.x = offsetx
    self.tileoffset.y = offsety
end

function TileSet:setOffsetX(offsetx)
    assert(type(offsetx) == 'number', "setOffsetX : param #1 must be a number type")
    self.tileoffset = self.tileoffset or {}
    self.tileoffset.x = offsetx
end

function TileSet:setOffsetY(offsety)
    assert(type(offsety) == 'number', "setOffsetY : param #1 must be a number type")
    self.tileoffset = self.tileoffset or {}
    self.tileoffset.y = offsety
end

--- Returns a prooperty value associated with the tileset.
---@param key string The key to lookup
---@return any
function TileSet:getProperty(key)
    if self.properties == nil then return end
    return self.properties:get(key)
end

--- Sets a property for the provided key.
---@param key string The property key
---@param value any The value to store for the property
function TileSet:setProperty(key, value)
    if self.properties == nil then return end
    self.properties:set(key, value)
end

--- Returns the number of properties for the object.
---@return integer numprops
function TileSet:getNumProperties()
    if self.properties == nil then return 0 end
    return self.properties:getNumProperties()
end

--- Returns true if the object contains a property with the key value.
---@param key string The property key
---@return boolean
function TileSet:hasPropertyKey(key)
    if self.properties == nil then return false end
    return self.properties:hasKey(key)
end

return TileSet