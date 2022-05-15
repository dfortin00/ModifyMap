local lib = (...):gsub("mapfactory.ObjectLayer$", '')
local cwd = (...):gsub("%.ObjectLayer$", '') .. '.'

local utils     = require(lib .. "utils")
local Class     = require(lib .. "class")
local maputils  = require(cwd .. 'maputils')
local MapObject = require(cwd .. 'MapObject')

local ObjectLayer = Class{__name='ObjectLayer'}
local Layer

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Builds the object layer data.
---@param layer table The current object layer
---@param map table The current map
local function _build_object_layer(layer, map)
    if layer.draworder == 'topdown' then
        table.sort(layer.objects, function(a, b)
            return a.y + a.height < b.y + b.height
        end)
    end

    for _, object in ipairs(layer.objects) do
        -- Need to move things around a bit to handle a naming conflict with the Class library.
        object.objecttype = object.type
        object.type = nil

        setmetatable(object, MapObject)
        object:init(layer, map)

        map.objects.layers = map.objects.layers or {}
        map.objects.layers[object:getId()] = object
    end
end

--- Draws polygons shapes for layer objects.
---@param object table Flat array of x,y coordinate pairs that make up object shape
---@param shape string rectangle|ellipse|polyline|polygon
---@param linecolor table RGB color table for line color
---@param fillcolor table RGB color table for fill color
local function _draw_shape(object, shape, linecolor, fillcolor)
    local vertices = maputils.flattenVertexTable(object)
    if shape == 'polyline' then
        utils.colors.setColor(linecolor)
        love.graphics.line(vertices)
        return
    elseif shape == 'polygon' then
        utils.colors.setColor(fillcolor)
        if not love.math.isConvex(vertices) then
            local triangles = love.math.triangulate(vertices)
            for _, triangle in ipairs(triangles) do
                love.graphics.polygon('fill', triangle)
            end
        else
            love.graphics.polygon('fill', vertices)
        end
    else
        utils.colors.setColor(fillcolor)
        love.graphics.polygon('fill', vertices)
    end

    utils.colors.setColor(linecolor)
    love.graphics.polygon('line', vertices)
end

--- Draws a tile object for object layers.
---@param layer table The current object layer
---@param tobj table The tile object to be rendered
local function _render_tile_object(layer, tobj)
    local map = layer:getMap()
    local gid = tobj:hasAnimation() and tobj:getAnimation():getCurrentGid() or tobj:getGid()
    local frametile = map:getTile(gid)

    local offsetx, offsety = layer:getOffsets()
    local x, y, r, sx, sy, ox, oy = tobj:getDrawCoords()
    if frametile:isAtlas() then
        love.graphics.draw(frametile:getImage(), frametile:getQuad(), x + offsetx, y + offsety, r, sx, sy, ox, oy)
    else
        love.graphics.draw(frametile:getImage(), x + offsetx, y + offsety, r, sx, sy, ox, oy)
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Set up layer and build objects.
---@param map table The current map
---@param parent? table The parent group folder containing this layer
function ObjectLayer:init(map, parent)
    Layer.init(self, map, '', parent)
    _build_object_layer(self, map)
end

--- Checks if the object layer has an object that matches the provided object id.
---@param objectid string|number Either the name of the object or the object id
---@return boolean
function ObjectLayer:hasObject(objectid)
    return pcall(self.getObject, self, objectid)
end

--- Returns an object by either its name or by the id in the object layer.
---@param objectid string|number The name or id of the object to retrieve
---@return table mapobject
function ObjectLayer:getObject(objectid)
    local type_id = type(objectid)
    assert((type_id == 'string') or (type_id == 'number'),
        'getObject : objectid must be either a string name or the numerical id : id=' .. tostring(objectid))

    local mapobject
    if (type_id == 'string') then
        for _, object in pairs(self.objects) do
            if object:getName() == objectid then mapobject = object; break end
        end
    else
        for _, object in pairs(self.objects) do
            if object:getId() == objectid then mapobject = object; break end
        end
    end

    assert(mapobject, "getObject : object with specified object id does not exist on object layer : id=" .. tostring(objectid))
    return mapobject
end

--- Returns the table containing the list of map objects.
---@return table objects
function ObjectLayer:getObjects()
    return self.objects
end

--- Retrieves a list of objects that share the same name. If no name is provided, the
--- method will return a reference to the internal objects list.
---@param name string The name of the objects to locate
---@return table objects
function ObjectLayer:getAllObjectsWithName(name)
    if not name then return self.objects end

    local objects = {}
    for _, object in ipairs(self.objects) do
        if object:getName() == name then
            table.insert(objects, object)
        end
    end

    return objects
end

--- Default render method.
function ObjectLayer:render()
    local line = color.byte2norm(160, 160, 160, 255 * self:getOpacity())
    local fill = color.byte2norm(255, 255, 255, 255 * self:getOpacity() * 0.5)

    local r, g, b, a = love.graphics.getColor()
    local reset = {r, g, b, a * self:getOpacity()}

    for _, object in ipairs(self.objects) do
        if object:isVisible() then
            if object:getShape() == 'rectangle' and not object:getGid() then
                _draw_shape(object.rectangle, 'rectangle', line, fill)
            elseif object:getShape() == 'ellipse' then
				_draw_shape(object.ellipse, 'ellipse', line, fill)
			elseif object:getShape() == 'polygon' then
				_draw_shape(object.polygon, 'polygon', line, fill)
			elseif object:getShape() == 'polyline' then
				_draw_shape(object.polyline, 'polyline', line, fill)
			elseif object:getShape() == 'point' then
                local offsetx, offsety = self:getOffsets()
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.setPointSize(3)
                love.graphics.points({object.x + offsetx, object.y + offsety})
            elseif object:getShape() == 'tileobject' then
                utils.colors.setColor(reset)
                _render_tile_object(self, object)
            end
        end
    end

    love.graphics.setColor(r, g, b, a)
end

--==========================
--==[[ MODULE METHODS ]]==--
--==========================

return function(parentClass)
    assert(utils.class.isClass(parentClass), "ObjectLayer : parentClass not a valid class")
    assert(utils.class.typeOf(parentClass, "Layer"), "ObjectLayer : parentClass must be a Layer class")

    ObjectLayer:include(parentClass)
    Layer = parentClass
    return ObjectLayer
end