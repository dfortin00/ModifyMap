
assert(love.getVersion() >= 11, 'MapMatic library requires LOVE2D version 11.0+')

local MapFactory = {
    __name        = "MapMatic",
    __version     = '0.1.0',
    __license     = "MIT/X11",
    __description = "A LOVE2D library for rendering and controlling tile maps created with the Tiled application",
    __cache       = {},
}
MapFactory.__index = MapFactory

local utils = require((...):gsub("%.mapfactory$", '') .. ".utils")
local Map   = require((...) .. '.Map')

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

local function _check_config_params(config)
    if not config then return end
    utils.params('init')
        :start(config, 2):isTable()
        :start(config.offsetx, 0, "config.offsetx"):ifNotNil():isNumber()
        :start(config.offsety, 0, "config.offsety"):ifNotNil():isNumber()
end

--- Creates a new map from a Tiled map.
---@param filepath string Path to exported Tiled map file
---@param config table Configuration table
local function _new_map(factory, filepath, config)
    local _, _, ext = utils.string.splitPath(filepath)

    _check_config_params(config)

    if ext == '' then
        filepath = filepath .. '.lua'
    else
        assert(ext == 'lua', 'Invalid map file : File must be of type .lua : ' .. filepath)
    end

    assert(love.filesystem.getInfo(filepath), 'Invalid map file : File does not exist : ' .. filepath)

    local map = setmetatable(love.filesystem.load(filepath)(), Map)
    map.factory = factory
    map:init(filepath, config)

    return map
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Set up the MapFactory table as a callable object.
---@return table map
function MapFactory.__call(self, filepath, config)
    return _new_map(self, filepath, config)
end

--- Returns the image cache table for the MapMatic library.
---@return table cache
function MapFactory:getCache()
    return self.__cache
end

--- Returns a single cached image from the table.
---@param name string Name of the cached item to retrieve.
---@return userdata image
function MapFactory:getCacheItem(name)
    return self.__cache[name]
end

--- Clears the global map image __cache.
--- WARNING: Calling this method while using an active map can have adverse affects.
function MapFactory:clearCache()
    for k in pairs(self.__cache) do
        MapFactory.__cache[k] = nil
    end
end

--- Returns the name of the MapMatic library.
---@return string
function MapFactory:name()
    return self.__name
end

--- Returns the version of the MapMatic library.
function MapFactory:version()
    return self.__version
end

--- Returns the license type for the MapMatic library.
---@return string
function MapFactory:license()
    return self.__license
end

--- Returns the description of the MapMatic library.
function MapFactory:description()
    return self.__description
end

return setmetatable({}, MapFactory)
