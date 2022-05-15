
local lib = (...):gsub('mapfactory.Map', '')
local cwd = (...):gsub("%.Map$", '') .. '.'

local utils   = require(lib .. "utils")
local Class   = require(lib .. "class")
local TObject = require(cwd .. "TObject")

local TileSet = require(cwd .. "TileSet")

local Layer       = require(cwd .. "Layer")
local GroupLayer  = require(cwd .. "GroupLayer")(Layer)
local TileLayer   = require(cwd .. "TileLayer")(Layer)
local ObjectLayer = require(cwd .. "ObjectLayer")(Layer)
local ImageLayer  = require(cwd .. "ImageLayer")(Layer)

local MapProperties = require(cwd .. "MapProperties")

local Map = Class{__name="Map", __includes=TObject}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Determines if the object is a valid layer. The optional layertype can be used to also determine
--- if the type of the layer.
---@param layer table The table object to check
---@param layertype any (optional) Can be used to also determine if the layer is a specific layer type
---@return boolean
local function _is_layer(layer, layertype)

    local islayer = utils.class.typeOf(layer, "Layer")
    if islayer and layertype then
        islayer = islayer and (layer:getLayerType() == layertype) or false
    end

    return islayer
end

--- Filters layers into sub groups inside the table. Layers are grouped using the plural
--- form of the layer type (e.g. filtered.tilelayers, filtered.groups, etc...)
---@param layers any
---@return table
local function _filter_layers(layers)
    local filtered = {}
    for _, layer in ipairs(layers) do
        local layertype = layer:getLayerType() .. "s"
        filtered[layertype] = filtered[layertype] or {}
        table.insert(filtered[layertype], layer)
    end
    return filtered
end

--- Loads images and sets up tiles.
---@param map table The current map
---@param path any The path the exported map file resides in
local function _build_tilesets(map, path)
    for index, tileset in ipairs(map.tilesets) do
        setmetatable(tileset, TileSet)
        tileset:init(map, path, index)
    end
end

--- Builds a new layer class object based on the layer type.
---@param layer table The layer table taken from the exported Tiled map
---@param map any The current map
---@param path any The path the exported map file resides in
local function _build_layer_class(layer, map, path)
    -- Need to move things around a bit to handle a naming conflict with the Class library.
    layer.layertype = layer.type
    layer.type = nil

    if layer.layertype == "group" then
        setmetatable(layer, GroupLayer)
        layer:init(map)

    elseif layer.layertype == "tilelayer" then
        setmetatable(layer, TileLayer)
        layer:init(map)

    elseif layer.layertype == "objectgroup" then
        setmetatable(layer, ObjectLayer)
        layer:init(map)

    elseif layer.layertype == "imagelayer" then
        setmetatable(layer, ImageLayer)
        layer:init(map, path)
    else
        setmetatable(layer, Layer)
        layer:init(map, path)
    end
end

--- Converts layer tables into Layer objects.
---@param map table The current map
---@param path string The path the exported map file resides in
local function _build_layers(map, path)
    local layers = {}
    for _, layer in ipairs(map.layers) do
        _build_layer_class(layer, map, path)
        table.insert(layers, layer)
    end
    map.layers = layers
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Constructs the new Map object.
---@param path string The file path to the Tiled map export file
---@param config table The configuration table
function Map:init(path, config)
    config = config or {}

    self.offsetx = config.offsetx or 0
    self.offsety = config.offsety or 0

    -- Reference tables for quick lookups.
    self.tiles      = {}
    self.objects    = {}
    self.animations = {}
    self.layerpaths = {}

    self.properties = MapProperties(self)

    -- Parallax origin
    self.parallaxoriginx = (self.parallaxorigin) and self.parallaxorigin.x or 0
    self.parallaxoriginy = (self.parallaxorigin) and self.parallaxorigin.y or 0
    self.parallaxorigin  = nil -- Don't need this anymore.

    -- Exported Lua map file properties.
    path = {utils.string.splitPath(path)}
    self.directory = path[1]
    self.mapname = string.gsub(path[2], "%.%w+$", "")

    -- Build the map.
    self:resize()
    _build_tilesets(self, self.directory)
    _build_layers(self, self.directory)
end

--- Returns the MapFactory class that was used to generate this map object.
---@return table factory
function Map:getFactory()
    return self.factory
end

--- Loads a single plugin for the map and calls the plugin init() method. By default, the first
--- parameter passed into the plugin init() method will always be a reference to the map object.
---@param name string The name of the plugin inside the /plugins subdirectory.
---@param ... any Additional parameters passed into the plugin init method.
---@return table plugin
function Map:loadPlugin(name, ...)
    self.__plugins = self.__plugins or {}
    assert(not self.__plugins[name], "loadPlugin : plugin has already been loaded for this map : name=" .. name)

    local success, PluginClass = pcall(require, lib .. "plugins." .. name)
    assert(success, "loadPlugin : unable to load map plugin : name=" .. name .. "\n" .. tostring(PluginClass))
    assert(utils.class.typeOf(PluginClass, "PluginBase"),
        "loadPlugin : plugin object must be a child of PluginBase class : name=" .. name)

    -- Call the plugin class and pass in the map as its first parameter.
    local plugin = PluginClass(self, ...)
    self.__plugins[name] = plugin

    return plugin
end

--- Returns the interface for a previously loaded plugin.
---@param name string The name of the plugin to retrieve.
---@return table plugin
function Map:plugin(name)
    assert(type(name) == "string", "plugin : plugin name parameter must be a string value")
    assert(self.__plugins, "plugin : no plugins have been loaded for this map")
    assert(self.__plugins[name], "plugin : no such plugin has been loaded for this map : name=" .. name)
    return self.__plugins[name]
end

--- Returns the name of the map without directory or extension.
---@return string
function Map:getMapName()
    return self.mapname
end

--- Returns the directory of the exported Tiled map file that was used to create this object.
---@return string location
function Map:getDirectory()
    return self.directory
end

--- Returns the full directory and filename of the exported Tiled map file that was used to created this object.
---@param includeDirectory? boolean If true, the fully qualified directory is included in the filename.
---@return string filename
function Map:getFileName(includeDirectory)
    includeDirectory = (includeDirectory == nil) and true or (includeDirectory == true)
    local directory = (includeDirectory == true) and self:getDirectory() or ""
    return directory .. self:getMapName() .. ".lua"
end

--- Returns the xy pixel coordinate of a tile in the map tile grid.
---@param row number The tile row coordinate
---@param col number The tile column coordinate
---@return number tileX, number tileY
function Map:getTilePosition(col, row)
    local tileW = self:getTileWidth()
    local tileH = self:getTileHeight()
    local tileX, tileY

    if self.orientation == "orthogonal" then
        tileX = col * tileW
        tileY = row * tileH

    elseif self.orientation == "isometric" then
        tileX = (col - row) * (tileW * 0.5) + self:getWidth() * tileW * 0.5 - tileW * 0.5
        tileY = (col + row - 2) * (tileH * 0.5)

    else
        -- hexagon maps
        local sidelength = self.hexsidelength or 0
        local oddStagger = (self.staggerindex == "odd")

        if self.staggeraxis == "y" then
            local isEven = (row % 2 == 0)
            local test = (oddStagger and isEven) or (not oddStagger and not isEven)
            local widthoffset = test and (tileW * 0.5) or 0
            local rowH = tileH - (tileH - sidelength) * 0.5

            tileX = (col - 1) * tileW + widthoffset
            tileY = (row - 1) * rowH + tileH
        else
            local isEven = (col % 2 == 0)
            local test = (oddStagger and isEven) or (not oddStagger and not isEven)
            local heightoffset = test and (tileH * 0.5) or 0
            local colW = tileW - (tileW - sidelength) * 0.5

            tileX = (col - 1) * colW
            tileY = (row - 1) * tileH + heightoffset
        end
    end

    return tileX, tileY
end

--- Returns the width of the map in pixels.
---@return number
function Map:getMapWidth()
    return self.width * self.tilewidth
end

-- Returns the height of the map in pixels.
---@return number
function Map:getMapHeight()
    return self.height * self.tileheight
end

--- Returns the width of the tiles in the map.
---@return number
function Map:getTileWidth()
    return self.tilewidth
end

--- Returns the height of the tiles in the map.
---@return number
function Map:getTileHeight()
    return self.tileheight
end

--- Returns the orientation of the map (orthogonal, isometric, or hexagon)
---@return string orientation
function Map:getOrientation()
    return self.orientation
end

--- Resize the drawing area for the map canvas.
---@param w number The width of the map canvas area in pixels
---@param h number The height of the map canvas area in pixels
function Map:resize(w, h)
    w = w or love.graphics.getWidth()
    h = h or love.graphics.getHeight()

    self.canvas = love.graphics.newCanvas(w, h)
    self.canvas:setFilter("nearest", "nearest")
end

--- Returns the canvas for the map. The dimensions of this canvas also act as the viewport
--- when rendering layers.
---@return userdata canvas
function Map:getCanvas()
    return self.canvas
end

--- Returns the parallax origin for the x and y axes.
---@return number parallaxoriginx, number parallaxoriginy
function Map:getParallaxOrigin()
    return self:getParallaxOriginX(), self:getParallaxOriginY()
end

--- Returns the parallax origin for the x axis.
---@return number parallaxoriginx
function Map:getParallaxOriginX()
    return self.parallaxoriginx
end

--- Returns the parallax origin for the y axis.
---@return number parallaxoriginy
function Map:getParallaxOriginY()
    return self.parallaxoriginy
end

--- Sets the parallax origin for the x and y axes.
---@param originx number The parallax origin for the x axis
---@param originy number The parallax origin for hte y axis
function Map:setParallaxOrigin(originx, originy)
    self:setParallaxOriginX(originx)
    self:setParallaxOriginY(originy)
end

--- Sets the parallax origin for the x axis.
---@param originx number The parallax origin for the x axis.
function Map:setParallaxOriginX(originx)
    assert(type(originx) == "number", "setParallaxOriginX : param #1 must be a number type")
    self.parallaxoriginx = originx
end

--- Sets the parallax origin for the y axis.
---@param originy number The parallax origin for the y axis.
function Map:setParallaxOriginY(originy)
    assert(type(originy) == "number", "setParallaxOriginY : param #1 must be a number type")
    self.parallaxoriginy = originy
end

--- Retrieves a layer from the map. Note: The layerid is relative to the grouplayer parameter. If no
--- grouplayer is provided, the indexing will be done from the root level.
---@param layerid string|table Either the name or the index of the layer to be retrieved
---@param grouplayer? table The search will be done relative to the provided group layer
---@return table layer
function Map:getLayer(layerid, grouplayer)
    local type_id = type(layerid)
    assert((type_id == "string") or (type_id == "number"),
        "getLayer : layerid must be either a string path or a number index : id=" .. tostring(layerid))

    local layer
    if grouplayer then
        assert(_is_layer(grouplayer, "group"), "getLayer : parameter #2 is not a valid group layer")

        if (type_id == "string") then
            local path = grouplayer.layerpath .. "." .. layerid
            layer = self.layerpaths[path]
        else
            layer = grouplayer.layers[layerid]
        end
    else
        if (type_id == "string") then
            layer = self.layerpaths[layerid]
        else
            layer = self.layers[layerid]
        end
    end

    assert(layer, "getLayer : layer does not exist in the lookup table : id=" .. layerid)
    assert(_is_layer(layer), "getLayer : unknown issue found - unable to retrieve layer : id=" .. layerid)

    return layer
end

--- Returns a table of all layers in the map. If the "grouped" parameter is set to true, the layers
--- will be sorted into groups of the same layer type. If the parameter is set to false (or nil), the
--- method will return a flat array of all layers the order of their layer index.
---@param grouped boolean Filters the layers into separate groups when set to true
---@return table layers
function Map:getLayers(grouped)
    local layers = {}
    for index, layer in ipairs(self.layerpaths) do
        layers[index] = layer
    end

    if grouped == true then
        layers = _filter_layers(layers)
    end

    return layers
end

--- Determines whether the map has a layer with the specified id.
---@param layerid string|table Either the name or the index of the layer to be retrieved
---@param grouplayer? table The search will be done relative to the provided group layer
---@return boolean success, table|string layerOrError
function Map:hasLayer(layerid, grouplayer)
    return pcall(self.getLayer, self, layerid, grouplayer)
end

--- Returns the tileset either by name or by tileset index.
---@param tilesetid number|string The id of the tileset
---@return table tileset
function Map:getTileSet(tilesetid)
    local type_id = type(tilesetid)
    assert(type_id == "number" or type_id == "string",
        "getTileSet : invalid tileset identifier passed into method : id="..tostring(tilesetid))

    if type_id == "string" then
        for _, tileset in ipairs(self.tilesets) do
            if tileset.name == tilesetid then return tileset end
        end
    else
        return self.tilesets[tilesetid]
    end
end

--- Retrieves a global tile loaded from a tileset.
---@param gid number The global ID value for the tile
---@return table|nil tile
function Map:getTile(gid)
    if not gid then return end
    return self.tiles[gid]
end

--- Retrieves a global object that was loaded by an ObjectLayer.
---@param objectid number|string The ID of the layer object
---@return table|nil object
function Map:getLayerObject(objectid)
    local type_id = type(objectid)
    assert(type_id == "number" or type_id == "string",
        "getLayerObject : invalid layer object identifier passed into method : id="..tostring(objectid))

    if type_id == "string" then
        if objectid == "" then return end
        for _, object in pairs(self.objects.layers) do
            if object.name == objectid then return object end
        end
    else
        return self.objects.layers[objectid]
    end
end

--- Retrieves a global object that was loaded by a tile.
---@param objectid number|string The ID of the tile object
---@return table|nil object
function Map:getTileObject(objectid)
    if not self.objects.tiles then return end
    local type_id = type(objectid)
    assert(type_id == "number" or type_id == "string",
        "getTileObject : invalid layer object identifier passed into method : id="..tostring(objectid))

    if type_id == "string" then
        if objectid == "" then return end
        for _, object in pairs(self.objects.tiles) do
            if object.name == objectid then return object end
        end
    else
        return self.objects.tiles[objectid]
    end
end

--- Update tile animations and layers.
---@param dt number The delta time between the current frame and the last frame.
function Map:update(dt)
    for _, animations in pairs(self.animations) do
        for _, item in ipairs(animations) do
            local anim = item:getAnimation()
            local frame = anim:getCurrentFrame()

            anim:update(dt)

            local gid = anim:getCurrentGid()
            local frametile = self:getTile(gid)

            -- Update sprite batch animations when using tile sheets and batches are enabled for layer.
            if (item:type() == "TileInstance") and not (frame == anim:getCurrentFrame()) and
               item:getOwner():usesBatchDraw() and (frametile:isAtlas())
            then
                item.batch:set(item:getBatchId(), frametile:getQuad(), item:getDrawCoords())
            end
        end
    end

    for _, layer in ipairs(self.layers) do
        layer:update(dt)
    end
end

--- Draws a single layer to the active drawing surface. This method ignores the layer visibility flag.
---@param layerid number|string The name or index of the layer to render
---@param tx number The amount to translate the layer along the x-axis
---@param ty number The amount to translate the layer along the y-axis
---@param grouplayer? table The group layer to search in for the layer to render
function Map:renderLayer(layerid, tx, ty, grouplayer)
    local layer = _is_layer(layerid) and layerid or self:getLayer(layerid, grouplayer)

    local oldColor = utils.colors.getColor()
    local newColor = utils.colors.getColor()
    utils.colors.setOpacity(newColor, layer:getOpacity())

    utils.colors.setColor(newColor)
    love.graphics.push()
    love.graphics.origin()

    local translatex = self:getParallaxOriginX() + (-math.floor(tx or 0) * layer:getParallaxX())
    local translatey = self:getParallaxOriginY() + (-math.floor(ty or 0) * layer:getParallaxY())
    love.graphics.translate(translatex, translatey)
    layer:render(translatex, translatey)

    love.graphics.pop()
    utils.colors.setColor(oldColor)
end

--- Draws the map to the screen.
---@param tx number Translation override in the x-direction
---@param ty number Translation override in the y-direction
---@param sx number Scalling override in the x-direction
---@param sy number Scalling override in the y-direction
function Map:render(tx, ty, sx, sy)
    local currentCanvas = love.graphics.getCanvas()

    self.canvas:renderTo(function()
        love.graphics.clear()

        for _, layer in ipairs(self.layerpaths) do
            if layer:isVisible() and (layer:getOpacity() > 0) then
                self:renderLayer(layer, tx, ty)
            end
        end
    end)

    love.graphics.push()
    if sx or (sx and sy) then
        love.graphics.origin()
        love.graphics.scale(sx, sy or sx)
    end

    love.graphics.setCanvas(currentCanvas)
    love.graphics.draw(self.canvas)

    love.graphics.pop()
end

return Map