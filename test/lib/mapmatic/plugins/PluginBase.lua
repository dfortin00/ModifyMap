local lib = (...):gsub("plugins.PluginBase$", '')
local Class = require(lib .. "class")

local PluginBase = Class{__name="PluginBase"}

function PluginBase:init(map)
    self.map = map
end

function PluginBase:getMap()
    return self.map
end

function PluginBase:licence()
    return self.__license
end

function PluginBase:description()
    return self.__description
end

return PluginBase