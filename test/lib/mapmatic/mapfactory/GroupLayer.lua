local lib = (...):gsub("mapfactory.GroupLayer$", '')

local utils = require(lib .. "utils")
local Class = require(lib .. "class")

local GroupLayer = Class{__name = "GroupLayer"}
local Layer

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Creates a new group layer to add to the layer structure of the map.
---@param map table The current map
---@param parent? table The parent group layer that contains this layer
function GroupLayer:init(map, parent)
    Layer.init(self, map, '', parent)
    self.layers = self.layers or {}
end

--- Returns the number of layers contained within the group folder. This method
--- only counts the immediate layers, and does not count any layers contained within subgroups.
---@return number numLayers
function GroupLayer:getNumChildren()
    return #self.layers
end

--- Returns a child layer contained within the group.
---@param layerid integer|string Either the index of the child layer, or the layer path relative to this group layer.
---@return table layer
function GroupLayer:getChildLayer(layerid)
    return self.map:getLayer(layerid, self)
end

--- Determines if this group layer contains a child layer that matches the layer id.
---@param layerid integer|string Either the index of the child layer, or the layer path relative to this group layer.
---@return boolean
function GroupLayer:hasLayer(layerid)
    return self.map:hasLayer(layerid, self)
end

--- Draws a single layer to the active drawing surface. This method ignores the layer visibility flag.
---@param layerid number|string The name or index of the layer to render
---@param tx number The amount to translate the layer along the x-axis
---@param ty number The amount to translate the layer along the y-axis
function GroupLayer:renderLayer(layerid, tx, ty)
    self.map:renderLayer(layerid, tx, ty, self)
end

--==========================
--==[[ MODULE METHODS ]]==--
--==========================

return function(parentClass)
    assert(utils.class.isClass(parentClass), "GroupLayer : parentClass not a valid class")
    assert(utils.class.typeOf(parentClass, "Layer"), "GroupLayer : parentClass must be a Layer class")

    GroupLayer:include(parentClass)
    Layer = parentClass
    return GroupLayer
end