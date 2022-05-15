local lib = (...):gsub("plugins.ModifyMap.MapEntity$", '')
local cwd = (...):gsub("%.ModifyMap.MapEntity$", '') .. '.'

local Class         = require(lib .. "class")
local collision     = require(lib .. "collision")
local TObject       = require(cwd:gsub("plugins", 'mapfactory') .. "TObject")
local MapProperties = require(cwd:gsub("plugins", 'mapfactory') .. 'MapProperties')

local MapEntity = Class{__name = 'MapEntity', __includes = TObject}

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Creates a basic entity outline that can be stored inside a CustomLayer on the map.
--- All entities added to the layer must be derived from this parent class.
---@param defs table Definitions table.
function MapEntity:init(defs)
    if not defs then defs = {} end

    self.name = defs.name or "default"

    -- MapEntity drawing coordinates.
    self.x        = defs.x or 0
    self.y        = defs.y or 0
    self.width    = defs.width or 1
    self.height   = defs.height or 1
    self.rotation = defs.rotation or 0
    self.sx       = defs.sx or 1
    self.sy       = defs.sy or 1
    self.ox       = defs.ox or 0
    self.oy       = defs.oy or 0

    -- Offsets
    self.offsetx  = defs.offsetx or 0
    self.offsety  = defs.offsety or 0

    -- Visibility
    self.visible = (defs.visible == nil) and true or (defs.visible == true)
    self.opacity = defs.opacity or 1

    -- Properties.
    local props = defs.properties or {}
    self.properties = MapProperties(props)
end

--- The owner is only set once the MapEntity is added using the CustomLayer:addEntity() method.
---@return table layer
function MapEntity:getOwner()
    return self.owner
end

--- Returns the index the entity can be found inside the custom layer lookup table.
--- The entity index is only set once the MapEntity is added using the CustomLayer:addEntity() method.
---@return number index
function MapEntity:getIndex()
    return self.entityindex
end

--- Determines if the entity has collided with a second target.
---@param target table Table that must contains x, y, width, and height keys
---@return boolean
function MapEntity:collides(target)
    local x, y, w, h = self:getRect()

    local tx, ty, tw, th
    if target.getRect and (type(target.getRect) == "function") then
        tx, ty, tw, th = target:getRect()
    elseif target.x and target.y and target.width and target.height then
        tx, ty, tw, th = target.x, target.y, target.width, target.height
    else
        tx, ty, tw, th = target[1], target[2], target[3], target[4]
    end

    return collision.rectRect(x, y, w, h, tx, ty, tw, th)
end

return MapEntity