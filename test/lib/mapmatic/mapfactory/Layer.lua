local lib = (...):gsub("mapfactory.Layer$", '')
local cwd = (...):gsub("%.Layer$", '') .. '.'

local utils   = require(lib .. "utils")
local Class   = require(lib .. "class")
local TObject = require(cwd .. "TObject")

local Layer = Class{__name='Layer', __includes=TObject}

local maputils      = require(cwd .. 'maputils')
local MapProperties = require(cwd .. 'MapProperties')

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Retrieves the parent map that contains the layer.
---@return table map
function Layer:getMap()
    return self.map
end

--- Determines if the layer is contained within a group folder.
---@return boolean
function Layer:isChild()
    return not (self:getParent() == nil)
end

--- Determines if the layer is contained within a group folder.
---@return boolean
function Layer:hasParent()
    return self:isChild()
end

--- Returns true if the layer is a group layer containing at least one child layer.
---@return boolean
function Layer:isParent()
    if not self.layers then return false end
    return (#self.layers > 0)
end

--- Determines if the layer is a parent group folder.
---@return boolean
function Layer:hasChildren()
    return self:isParent()
end

--- Retrieves the parent group folder containing the layer, or nil if the layer has no parent.
---@return table|nil parent
function Layer:getParent()
    return self.parent
end

--- Returns the type for the layer.
---@return string layerType
function Layer:getLayerType()
    return self.layertype
end

--- Returns the group path for the layer using dot notation.
---@return string layerPath
function Layer:getLayerPath()
    return self.layerpath
end

--- Returns the numerical order in which the layer was loaded in the map.
---@return number index
function Layer:getIndex()
    return self.layerindex
end

--- Return the index of the layer within its parent group layer, or use the root level of the map
--- if the layer is not contained inside a group folder.
---@return number index
function Layer:getGroupIndex()
    if self:isChild() then
        return self:getIndex() - self:getParent():getIndex()
    else
        for index, layer in ipairs(self.map.layers) do
            if layer == self then return index end
        end
    end
end

--- Returns the parallax multipliers for both axes.
---@return number parallaxx, number parallaxy
function Layer:getParallax()
    return self:getParallaxX(), self:getParallaxY()
end

--- Returns the parallax multiplier in the x direction.
---@return number parallaxx
function Layer:getParallaxX()
    local parentparallax = self:hasParent() and self:getParent():getParallaxX() or 1
    return self.parallaxx * parentparallax
end

--- Returns the parallax multiplier in the y direction.
---@return number parallaxy
function Layer:getParallaxY()
    local parentparallax = self:hasParent() and self:getParent():getParallaxY() or 1
    return self.parallaxy * parentparallax
end

--- Sets the x and y parallax multipliers for the layer.
---@param x number The factor to scroll the layer in the x-axis
---@param y number The factor to scroll the layer in the y-axis
function Layer:setParallax(x, y)
    assert(type(x) == 'number' , "setParallax : param #1 must be a number type")
    assert(type(y) == 'number' , "setParallax : param #2 must be a number type")
    self.parallaxx = x
    self.parallaxy = y
end

--- Sets the parallax multiplier in the x-axis.
---@param x number The factor to scroll the layer in the x-axis
function Layer:setParallaxX(x)
    assert(type(x) == 'number' , "setParallaxX : param #1 must be a number type")
    self.parallaxx = x
end

--- Sets the parallax multiplier in the y-axis.
---@param y number The factor to scroll the layer in the y-axis
function Layer:setParallaxY(y)
    assert(type(y) == 'number' , "setParallaxY : param #1 must be a number type")
    self.parallaxy = y
end

--- Determines if the layer is visible on the screen. If the layer is contained within a group
--- folder, the layer visiblity will also be determined by the parent's visibility flag.
---@return boolean
function Layer:isVisible()
    local parentvisible = true
    if self:hasParent() then parentvisible = self:getParent():isVisible() end
    return ((self.visible == true) and parentvisible)
end

--- Returns the layer offset in the x direction, taking into consideration the offsets of the layer parent.
---@return number offsetx
function Layer:getOffsetX()
    local parentoffset = self:hasParent() and self:getParent():getOffsetX() or self:getMap():getOffsetX()
    return self.offsetx + parentoffset
end

--- Returns the layer offset in the y direction, taking into consideration the offsets of the layer parent.
---@return number offsety
function Layer:getOffsetY()
    local parentoffset = self:hasParent() and self:getParent():getOffsetY() or self:getMap():getOffsetY()
    return self.offsety + parentoffset
end

function Layer:getOpacity()
    local parentopacity = self:hasParent() and self:getParent():getOpacity() or 1
    return self.opacity * parentopacity
end

--============================================================================================
-- Note: The following methods need to stay at the bottom of the file because of the top-down
--       way Lua loads modules. The Layer class needs to have its methods defined before it
--       can be passed in as a parameter to the class generators for the different layer
--       objects, otherwise the Layer methods won't be inherited by the child class.
--============================================================================================

--=========================
--==[[ PRIVATE METHODS ==--
--=========================

local GroupLayer  = require(cwd .. 'GroupLayer')(Layer)
local TileLayer   = require(cwd .. 'TileLayer')(Layer)
local ObjectLayer = require(cwd .. 'ObjectLayer')(Layer)
local ImageLayer  = require(cwd .. 'ImageLayer')(Layer)

--- By default, layer paths contain a dot-separated string of layer names starting from the root level.
--- Note: There is no logic in place to prevent a layer name from containing a '.' character, but this
--- should be discouraged as it might cause unexpected bugs.
---@param layer table The current layer
---@param map table The current map
---@param parent? table The parent group folder containing the current layer
local function _build_layer_path(layer, map, parent)
    local layerpath = parent and parent:getLayerPath()
    layer.layerpath = (layerpath and (layerpath..'.') or '') .. layer:getName()
    assert(not map.layerpaths[layer:getLayerPath()], "init : duplicate layer paths are not supported : path=" .. layer:getLayerPath())
    map.layerpaths[layer:getLayerPath()] = layer

    -- Add the layer reference again as an array index for easier map rendering.
    if utils.array.indexOf({"group", "tilelayer", "objectgroup", "imagelayer"}, layer:getLayerType()) then
        table.insert(map.layerpaths, layer)
        layer.layerindex = #map.layerpaths
    end
end

--- Builds a new layer class object based on the layer type.
---@param layer table The child layer to create
---@param map table The current map
---@param path string The path the exported Tiled map resides in
---@param parent table The group layer parent that contains this layer
local function _build_child_layer_class(layer, map, path, parent)

    -- Need to move things around a bit to handle a naming conflict with the Class library.
    layer.layertype = layer.type
    layer.type = nil

    if layer.layertype == 'group' then
        setmetatable(layer, GroupLayer)
        layer:init(map, parent)
    elseif layer.layertype == 'tilelayer' then
        setmetatable(layer, TileLayer)
        layer:init(map, parent)
    elseif layer.layertype == 'objectgroup' then
        setmetatable(layer, ObjectLayer)
        layer:init(map, parent)
    elseif layer.layertype == 'imagelayer' then
        setmetatable(layer, ImageLayer)
        layer:init(map, path, parent)
    else
        setmetatable(layer, Layer)
        layer:init(map, path, parent)
    end
end

--- Configure the layer data from the exported Tiled map data.
---@param layer table The layer to setup
---@param map table The current map
---@param path string The path the exported Tiled map resides in
---@param parent? table The parent group layer that contains this layer
local function _setup_layer(layer, map, path, parent)
    layer.properties = MapProperties(layer, parent or map)
    _build_layer_path(layer, map, parent)

    if layer:getLayerType() == "group" then
        for _, child in ipairs(layer.layers) do
            _build_child_layer_class(child, map, path, layer)
        end
    end

    if layer.encoding == 'base64' then
        layer.data = maputils.getDecompressedData(layer.data, layer.compression, map:getWidth(), map:getHeight())
    end

    layer.update     = layer.update or (function() end)
    layer.render     = layer.render or (function() end)
end

--=========================
--==[[ CLASS METHODS ==--
--=========================

--- Performs base initialization for all layer types.
---@param map table The current map
---@param path string The path the exported Tiled map resides in
---@param parent? table The parent group layer that contains this layer
function Layer:init(map, path, parent)
    self.map = map
    self.parent = parent
    if not path or path == '' then path = map:getDirectory() end
    _setup_layer(self, map, path, parent)
end

return Layer