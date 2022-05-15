local lib = (...):gsub("mapfactory.MapProperties", '')

local utils   = require(lib .. "utils")
local Class   = require(lib .. "class")

local MapProperties = Class{__name='MapProperties'}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Checks if the string value is a hexidecimal encoded color value.
---@param value any
---@return boolean
local function _is_color(value)
    local color = value
    if value:sub(1, 1) == "#" then
        color = value:sub(2)
    end

    -- Check is string is RGB or RGBA length.
    if not ((#color == 6) or (#color == 8)) then return false end

    for i = 1, #color do
        local char = color:sub(i, i)
        if not string.match(char, "[abcdefABCDEF0123456789]") then
            return false
        end
    end

    return true
end

--- Returns true if the string contains a three-letter extension.
---@param value string The string to test if it is a file
---@return boolean
local function _is_file(value)
    if value:match(".+%.%a%a%a$") then return true end
    return false
end

--- Gets the string property type: color, object, file, boolean, number, string, userdata, or function.
---@param value string The value to convert
---@return table property
local function _get_value_type(value)
    if (value == nil) then return nil end

    local type_v = type(value)
    local proptype = type_v

    if type_v == "string" then
        if _is_color(value) then
            value = utils.colors.toNorm(color.hex(value))
            proptype = "color"
        elseif _is_file(value) then
            proptype = "file"
        end
    elseif (type_v == "userdata") and value.type then
        proptype = value:type()
    elseif ((type_v == "table")) and value.id then
        proptype = "object"
    end

    return {value=value, type=proptype}
end

--- Set up the class properties.
---@param mapprops table The current properties object
---@param objprops table The table containing the properties
---@param isclass boolean True if the objprops is a MapProperties class
local function _setup_class_properties(mapprops, objprops, isclass)
    if isclass then
        mapprops.props = utils.table.copy(objprops.props)
    else
        mapprops.props = utils.table.copy(objprops or {})
    end
end

--- Copies the parent properties over to this class.
---@param mapprops table The current properties object
---@param parent table The parent properties to copy
local function _copy_parent_properties(mapprops, parent)
    if not parent then return end

    local parentprops = parent.properties or parent
    local isparentclass = utils.class.typeOf(parentprops, "MapProperties")
    local props = isparentclass and parentprops.props or parentprops

    for key, value in pairs(props) do
        if mapprops.props[key] == nil then
            mapprops.props[key] = isparentclass and value.value or value
        end
    end
end

--- Scans the properties table and makes an honest assessment of what each property type is.
---@param mapprops table The current properties class
---@param isclass boolean True if the class was copied from another MapProperties class
local function _determine_property_types(mapprops, isclass)
    if isclass then return end
    for key, value in pairs(mapprops.props) do
        mapprops.props[key] = _get_value_type(value)
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Takes a table that contains a properties key (e.g. { properties = {} }). The value of the
--- properties key can be either a table with a set of property keys, or an existing
--- MapProperties object.
---@param object table Table with "properties" key
---@param parent table Parent properties to inherit
function MapProperties:init(object, parent)
    object = object or {}

    local objprops = object.properties or object
    local isclass = utils.class.typeOf(objprops, "MapProperties")

    _setup_class_properties(self, objprops, isclass)
    _copy_parent_properties(self, parent)
    _determine_property_types(self, isclass)
end

--- Returns the type for an indicated property, or nil if the property does not exist.
---@param key string The property key name
---@return string type
function MapProperties:getPropertyType(key)
    if not self.props[key] then return end
    return self.props[key].type
end

--- Counts the number of properties the object contains.
---@return number count
function MapProperties:getNumProperties()
    return utils.table.getn(self.props)
end

--- Retrieves the value for a property, or nil if the property does not exist.
---@param key string The property key name
---@return any
function MapProperties:get(key)
    if not self.props[key] then return end
    return self.props[key].value
end

--- Sets the value for a property. If the value is nil, the property will be removed from the table.
---@param key string The property key name
---@param value any The proeprty value to store
---@param proptype? string Overrides the default type
function MapProperties:set(key, value, proptype)
    if value == nil then
        self.props[key] = nil
        return
    end

    if proptype then
        assert(type(proptype) == "string", "set : property type parameter must be a string")
        self.props[key] = {value=value, type=proptype}
    else
        self.props[key] = _get_value_type(value)
    end
end

--- Returns true if the table has a property with the provided key name.
---@param key string The property key name
---@return boolean
function MapProperties:hasKey(key)
    return not (self.props[key] == nil)
end

--- Returns an array containing the keys for all properties in the table.
--- Note: The order of the array is not guaranteed.
---@return table keys
function MapProperties:keys()
    return utils.table.keys(self.props)
end

--- Returns an array of values for all properties in the table.
--- Note: The order of the array is not guaranteed.
---@return table values
function MapProperties:values()
    local values = utils.table.values(self.props)
    local vtable = {}
    for _, value in ipairs(values) do
        table.insert(vtable, value.value)
    end
    return vtable
end

return MapProperties
