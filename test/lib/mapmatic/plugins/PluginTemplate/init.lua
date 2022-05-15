--[[
    Basic plugin template for the MapMatic library. Use this template to generate your own plugins.
    To create a plugin:
    1) Create a subdirectory with the name of the plugin inside the plugins folder.
    2) Create an init.lua file inside the subdirectory folder.
    3) Used the template below to create your plugin, replacing the name PluginTemplate with
    whatever name you wish to call your plugin class (it doesn't have to be the same as the
    plugin name, but it is standard practice to do so.)

    Using a plugin in code:
        local MapFactory = require("mapmatic")
        local map = MapFactory("assets/overworld_map")
        map:loadPlugin("PluginTemplate", "This is param1", "This is param2")
        map:plugin("PluginTemplate"):exampleMethod()
]]

--- lib will give you the directory of the MapMatic library folder.
--- cwd will give you the directory the plugin folder.
--- Replace "PluginTemplate" in the strings with the name of your plugin.
local lib = (...):gsub("plugins.PluginTemplate$", '')
local cwd = (...):gsub("%.PluginTemplate$", '') .. '.'

local Class      = require(lib .. "class")
local PluginBase = require(cwd .. "PluginBase")

--- Plugins are class objects that derive from the PluginBase class.
local PluginTemplate = Class {
    __name        = "PluginTemplate",
    __includes    = PluginBase,
    __version     = "1.0.0",
    __license     = "MIT/X11",
    __description = "Basic plugin template"
}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Example private method.
local function _example_private_method()
    return "private method"
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Note: The init() method is not directly called by the user but rather is automatically invoked
--- when the Map:loadPlugin() method is called. The first parameter to the init() method is always a
--- reference to the map object, and the remaining parameters are passed in through the loadPlugin()
--- method.
---@param map table The current map that owns this plugin instance
---@param param1 any
---@param param2 any
function PluginTemplate:init(map, param1, param2)
    -- Call the PluginBase.init() method and pass in the map.
    PluginBase.init(self, map)

    self.param1 = param1
    self.param2 = param2

    _example_private_method()
end

--- To call a plugin method from inside the user code, use the format:
---    Map:plugin("<pluginName>"):method()
function PluginTemplate:exampleMethod()
    return "PluginTemplate: example method"
end

return PluginTemplate