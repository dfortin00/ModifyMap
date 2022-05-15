
local lib = (...):gsub("plugins.ModifyMap$", '')
local cwd = (...):gsub("%.ModifyMap$", '') .. '.'

local utils      = require(lib .. "utils")
local Class      = require(lib .. "class")
local PluginBase = require(cwd .. "PluginBase")
local Layer      = require(lib .. "mapfactory.Layer")
local GroupLayer = require(lib .. "mapfactory.GroupLayer")(Layer)
local MapObject  = require(lib .. "mapfactory.MapObject")

-- Plugin definition
local ModifyMapPlugin = Class {
    __name        = "ModifyMapPlugin",
    __includes    = PluginBase,
    __version     = "1.0.0",
    __license     = "MIT/X11",
    __description = "Add and remove entities and layers to Tiled maps"
}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

-----------------------------------
-- Special Methods for Group Layers
-----------------------------------

--- Adds a new child group layer to this layer.
---@param name string The name of the child group layer
---@param index? integer The index to place the layer (defaults to the end of the child layer list)
---@return table layer
local function _add_group_layer(self, name, index)
    return self.map:plugin("ModifyMap"):addGroupLayer(name, index, self)
end

--- Adds a new custom layer to this layer.
---@param name string The name of the child custom layer
---@param index? integer The index to place the layer (defaults to end of the child layer list)
---@return table layer
local function _add_custom_layer(self, name, index)
    return self.map:plugin("ModifyMap"):addCustomLayer(name, index, self)
end

--- Removes a child layer. If the child is a group layer, then all sub layers beneath it will also be removed.
---@param layerid integer|string Either the index of the child layer, or the layer path relative to this gorup layer.
local function _remove_layer(self, layerid)
    self.map:plugin("ModifyMap"):removeLayer(layerid, self)
end

--- Helper method to add the necessary custom layer methods to a group layer.
---@param grouplayer table The group layer to add the methods to
local function _add_group_methods(grouplayer)
    grouplayer.addGroupLayer  = _add_group_layer
    grouplayer.addCustomLayer = _add_custom_layer
    grouplayer.removeLayer    = _remove_layer
end

-----------------------------------

--- Helper function for the Map:createMapObject() method. Checks the object definition table to make
--- sure it is structured in the correct format.
---@param object table The object table that will be used to create a new MapObject
---@param owner? table The owner of the map object
local function _check_create_map_object_defs(object, owner)
    local params = utils.params("createMapObject")
        :start(object):isTable()
        :start(object.shape, 0, "object.shape"):isString():anyOf("rectangle", "ellipse", "polygon", "polyline")
        :start(object.name, 0, "object.name"):ifNotNil():isString()
        :start(object.gid, 0, "object.gid"):ifNotNil():isNumber():gt(0)
        :start(object.x, 0, "object.x"):isNumber()
        :start(object.y, 0, "object.y"):isNumber()
        :start(object.width, 0, "object.width"):isNumber()
        :start(object.height, 0, "object.height"):isNumber()
        :start(object.rotation, 0, "object.rotation"):isNumber()
        :start(object.visible, 0, "object.visible"):isBoolean()
        :start(object.properties, 0, "object.properties"):isType("table", "MapProperties")

    -- Polygons
    if object.shape == "polygon" then
        params
            :start(object, 0, "object"):hasKeys("polygon")
            :start(object.polygon, 0, "object.polygon"):isTable()
        for index, vertex in ipairs(object.polygon) do
            params:start(vertex, 0, "object.polygon.vertex#"..tostring(index)):isTable():hasKeys("x", "y")
        end
    end

    -- Polylines
    if object.shape == "polyline" then
        params
            :start(object, 0, "object"):hasKeys("polyline")
            :start(object.polyline, 0, "object.polyline"):isTable()
        for index, vertex in ipairs(object.polyline) do
            params:start(vertex, 0, "object.polyline.vertex#"..tostring(index)):isTable():hasKeys("x", "y")
        end
    end

    -- Check the owner parameter.
    params:start(owner, 2):ifNotNil():isType("Layer", "Tile", "TileInstance", "MapEntity")
end

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

--- Resets the layer.layerindex value for each layer in the correct order.
---@param map table The current map
local function _reset_layer_indices(map)
    local layercount = 1
    local function count_layers(layers)
        for _, layer in ipairs(layers) do
            layer.layerindex = layercount
            layercount = layercount + 1

            if layer:getLayerType() == "group" then
                count_layers(layer.layers)
            end
        end
    end

    count_layers(map.layers)
end

--- Adds a new custom or group layer to the map.
---@param name string The name of the layer
---@param index integer The index to place the layer inside the parent layer
---@param grouplayer? table The parent group folder to place the layer
---@param map table The current map
---@param methodname string The name of the calling method
---@param layertype string Either "custom" or "group"
---@param class table The class object to create the layer instance
---@return table newlayer
local function _add_layer(name, index, grouplayer, map, methodname, layertype, class)
    assert(not (name == ""), methodname .. " : param #1 cannot be an empty string")
    if grouplayer then
        assert(_is_layer(grouplayer, "group"), methodname .. " : param #3 must be a valid group layer")
    end

    -- Index can be positive or negative. When negative, the index will start counting
    -- down from the end of the layers array.
    local layers = grouplayer and grouplayer.layers or map.layers
    if not index or (index > #layers) then index = #layers + 1 end
    if index < 1 then index = (#layers + 1) - math.abs(index) end
    if index < 1 then index = 1 end

    local newlayer = {
        id         = map.nextlayerid,
        name       = name,
        visible    = true,
        opacity    = 1,
        offsetx    = 0,
        offsety    = 0,
        parallaxx  = 1,
        parallaxy  = 1,
        layertype  = "custom", -- treat all new layers as "custom" for the moment.
        properties = {}
    }

    map.nextlayerid = map.nextlayerid + 1

    -- Create the layer class then set the layer"s layertype to the correct value.
    setmetatable(newlayer, class)
    newlayer:init(map, grouplayer)
    newlayer.layertype = layertype

    if newlayer.layertype == "group" then  _add_group_methods(newlayer) end

    table.insert(layers, index, newlayer)

    -- Insert the layer into the layerpath reference table.
    _reset_layer_indices(map)
    table.insert(map.layerpaths, newlayer.layerindex, newlayer)

    return newlayer
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Note: The init() method is not directly called by the user but rather is automatically invoked
--- when the ModifyMapPlugin:loadPlugin() method is called. The first parameter to the init() method is always a
--- reference to the map object, and the remaining parameters are passed in through the loadPlugin()
--- method.
---@param map table The current map that owns this plugin instance
function ModifyMapPlugin:init(map)
    -- Call the PluginBase.init() method and pass in the map.
    PluginBase.init(self, map)

     -- Used for map entities added to custom layers.
     map.nextentityid = 1

    for _, layer in ipairs(map:getLayers()) do
        if layer:getLayerType() == "group" then _add_group_methods(layer) end
    end
end

--- Creates a group folder that can be used to contain new custom layers.
---@param name string The name of the group folder (cannot be an empty string)
---@param index? number The index to place the group layer
---@param grouplayer? table The parent group folder to place the new group folder in
---@return table layer
function ModifyMapPlugin:addGroupLayer(name, index, grouplayer)
    return _add_layer(name, index, grouplayer, self:getMap(), "addGroupLayer", "group", GroupLayer)
end

--- Creates a custom layer that is capable of placing user data such as player sprites.
---@param name string The name of the custom layer (must be unique across other layers)
---@param index number The index the custom layer will be inserted into
---@param grouplayer? table The custom layer will be added relative to the provided group layer
---@param class? table The extended class definition that derives from CustomLayer
---@return table customLayer
function ModifyMapPlugin:addCustomLayer(name, index, grouplayer, class)
    return _add_layer(name, index, grouplayer, self:getMap(), "addCustomLayer", "custom", class or CustomLayer)
end

--- Removes a layer from the map. If the indicated layer being removed is a group folder, then all
--- sub-layers will be removed as well. All items associated with a layer (i.e. objects, animations,
--- etc...) will be removed as well.
---@param layerid number|string The id of the layer to remove
---@param grouplayer? table The layer search will be done relative to the provided group layer
function ModifyMapPlugin:removeLayer(layerid, grouplayer)
    local target = _is_layer(layerid) and layerid or self:getMap():getLayer(layerid, grouplayer)
    local map = self:getMap()

    -- Releases any SpriteBatches the layer might have.
    local function remove_batches(batches)
        if not batches then return end
        for _, batch in ipairs(batches) do
            if type(batch) == "table" then
                for _, cbatch in ipairs(batch) do
                    cbatch:release()
                end
            else
                batch:release()
            end
        end
    end

    -- Removes layer objects from the map object lookup table.
    local function remove_objects(layer)
        if not (layer:type() == "ObjectLayer") then return end

        for _, object in ipairs(layer.objects) do
            map.objects.layers[object.id] = nil
        end
    end

    -- Cleans up map data after layer has been removed.
    local function clean_up(layer)
        local layerpath = layer:getLayerPath()

        -- Release layer sprite batches.
        if (layer:type() == "TileLayer") then
            if layer.chunks then
                for _, chunk in ipairs(layer.chunks) do
                    remove_batches(chunk.batches)
                end
            else
                remove_batches(layer.batches)
            end
        end

        _reset_layer_indices(map)

        -- Remove layer items from lookup tables.
        table.remove(map.layerpaths, layer:getIndex())
        map.layerpaths[layerpath] = nil
        map.animations[layerpath] = nil
        remove_objects(layer)
    end

    -- Removes a layer from the map.
    local function remove_layer(layer, group)
        group = group or map

        for index = #group.layers, 1, -1 do
            local sublayer = group.layers[index]

            if sublayer:getLayerPath() == layer:getLayerPath() then

                -- Removing group folders also removes its child layers.
                if sublayer:getLayerType() == "group" then
                    for childindex = #sublayer.layers, 1, -1 do
                        local childlayer = sublayer:getChildLayer(childindex)
                        remove_layer(childlayer, sublayer)
                    end
                end

                table.remove(group.layers, index)
                clean_up(sublayer)

                return true

            elseif sublayer:getLayerType() == "group" then
                local ret = remove_layer(target, sublayer)
                if ret then return true end
            end
        end
    end

    remove_layer(target, grouplayer)
end

--- Changes the delimeter used to separate the layer paths in the map. The default is a "." character.
---@param c string Delimiting character.
function ModifyMapPlugin:changeLayerPathDelimiter(c)
    --- TODO: Method not implemented
    error("changeLayerPathDelimeter : method not implemented")

    assert(c and (type(c) == "string"), "changeLayerPathDelimter : param #1 must be a valid character")
    c = string.sub(c, 1, 1)
end


--- Creates a new MapObject class from an object definition table. The map object can either be
--- detached (no owner), or owned by a layer, tile, map entity or tile instance. If the owner
--- is either an ObjectLayer or Tile, the object will also be added to the respective object tables.
---@param object table Object definition
---@param owner? table The owner of the map object
---@param validate? boolean Set to false to skip parameter validation
---@return table mapobject
function ModifyMapPlugin:createMapObject(object, owner, validate)
    local map = self:getMap()

    -- Perform parameter validations.
    validate = (validate == nil) and true or (validate == true)
    if validate then _check_create_map_object_defs(object, owner) end

    -- Tile objects need to have shape initially set to "rectangle".
    if object.gid then object.shape = "rectangle" end

    object.id = map.nextobjectid
    map.nextobjectid = map.nextobjectid + 1

    setmetatable(object, MapObject)
    object:init(owner, map)

    -- Add the object to the proper object tables.
    if not owner then return object end
    if owner:type() == "ObjectLayer" then
        map.objects.layers = map.objects.layers or {}
        table.insert(map.objects.layers, object)
        table.insert(owner.objects, object)
    elseif owner:type() == "Tile" then
        map.objects.tiles = map.objects.tiles or {}
        table.insert(map.objects.tiles, object)

        owner.objectGroup = owner.objectGroup or {
            type       = "objectgroup",
            draworder  = "index",
            id         = 0, -- TODO: figure out where this id value comes from
            name       = "",
            visible    = true,
            opacity    = 1,
            offsetx    = 0,
            offsety    = 0,
            parallaxx  = 1,
            parallaxy  = 1,
            properties = {},
            objects    = {},
        }
        table.insert(owner.objectGroup.objects, object)
    end

    return object
end

return ModifyMapPlugin