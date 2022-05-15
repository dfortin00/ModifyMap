local lib = (...):gsub("plugins.ModifyMap.CustomLayer$", '')
local cwd = (...):gsub("%.CustomLayer$", '') .. '.'

local utils = require(lib .. "utils")
local Class = require(lib .. "class")
local Layer = require(cwd:gsub("plugins.ModifyMap", "mapfactory") .. "Layer")

local CustomLayer = Class{__name="CustomLayer", __includes=Layer}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Recalculate the entity indices.
---@param layer table The current custom layer
local function _recalculate_entity_indices(layer)
    for index, entity in ipairs(layer.entities) do
        entity.entityindex = index
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Creates a new custom layer to be added into the map hierarchy.
---@param map table The current map
---@param parent? table The parent group folder that contains this layer
function CustomLayer:init(map, parent)
    Layer.init(self, map, '', parent)
    self.entities = {}
end

--- Returns an entity from the table, or nil if it does not exist.
---@param id string|integer Either the name of the entity or the index into the entities table.
---@return table entity
function CustomLayer:getEntity(id)
    local type_id = type(id)
    assert(type_id == "string" or type_id == "number", "getEntity : param #1 must be either a string or an integer : id=" .. tostring(id))

    if type_id == "string" then
        for _, entity in ipairs(self.entities) do
            if entity:getName() == id then return entity end
        end
    else
        return self.entities[id]
    end
end

--- Adds an entity to the entity table.
---@param entity table Any object derived from the Entity class
---@param index? integer Index to place the entity in the table
function CustomLayer:addEntity(entity, index)
    assert(utils.class.typeOf(entity, "MapEntity"), "addEntity : param #1 must be a MapEntity type")

    if not index or (index > #self.entities) then index = #self.entities + 1 end
    if index < 1 then index = (#self.entities + 1) - math.abs(index) end
    if index < 1 then index = 1 end

    entity.owner = self
    entity.id = self.map.nextentityid

    self.map.nextentityid = self.map.nextentityid + 1

    table.insert(self.entities, index, entity)
    _recalculate_entity_indices(self)
end

--- Removes an entity from the list.
---@param id string|integer|table Either the name or id of the entity to remove, or a reference to the entity object.
---@return table|nil entity
function CustomLayer:removeEntity(id)
    local type_id = type(id)
    if type_id == "table" then
        assert(utils.class.typeOf(id, "MapEntity"), "removeEntity : param #1 must be either a string, integer or a MapEntity object")
    else
        assert(type_id == "string" or type_id == "number",
            "removeEntity : param #1 must be either a string, integer or a MapEntity object : id=" .. tostring(id))
    end

    local foundentity = nil
    if type_id == "string" then
        for _, entity in ipairs(self.entities) do
            if entity:getName() == id then
                table.remove(self.entities, entity:getIndex())
                foundentity = entity
                break
            end
        end
    elseif type_id == "number" then
        for _, entity in ipairs(self.entities) do
            if entity:getId() == id then
                table.remove(self.entities, entity:getIndex())
                foundentity = entity
                break
            end
        end
    else
        for _, entity in ipairs(self.entities) do
            if entity == id then
                table.remove(self.entities, entity:getIndex())
                foundentity = entity
                break
            end
        end
    end

    assert(foundentity, "removeEntity : no entity with provided id found on custom layer")
    _recalculate_entity_indices(self)
    return foundentity
end

--- Sorts the entities with a sorting function. The default is to reverse sort on the entity y-coordinate.
---@param sortFunc? function Function that will be used to sort the entities.
function CustomLayer:sortEntities(sortFunc)
    sortFunc = sortFunc or function(a, b) return a.y < b.y end
    assert(type(sortFunc) == "function",
        "sortEntities : param #1 must be a sorting function that returns a boolean value")

    table.sort(self.entities, sortFunc)
    _recalculate_entity_indices(self)
end

--- Runs the update method for each entity in the list.
---@param dt number The delta time between game frames
function CustomLayer:update(dt)
    for _, entity in ipairs(self.entities) do
        if entity.update then entity:update(dt) end
    end
end

--- Renders each entity in the list.
function CustomLayer:render()
    for _, entity in ipairs(self.entities) do
        if entity.render and entity:isVisible() and (entity:getOpacity() > 0) then
            entity:render()
        end
    end
end

--==========================
--==[[ MODULE METHODS ]]==--
--==========================

return CustomLayer
