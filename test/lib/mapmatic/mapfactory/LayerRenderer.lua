local lib = (...):gsub("mapfactory.LayerRenderer$", '')

local utils     = require(lib .. "utils")
local Class     = require(lib .. "class")
local collision = require(lib .. "collision")

local LayerRenderer = Class{__name='LayerRenderer'}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Adds tiles to look up table along with their x,y screen coordinates.
---@param renderer table The current layer renderer
---@param layer table The layer that owns the renderer
---@param chunk table Used with infinite maps
---@param params table Drawing instructions for render order
local function _position_tiles(renderer, layer, chunk, params)
    local data = chunk and chunk.data or layer.data

    for row = params.startRow, params.endRow, params.incrementRow do
        local tilerow = data[row]
        if not next(tilerow) then goto continue end

        local tilecols = utils.table.keys(tilerow)
        if #tilecols > 1 then
            table.sort(tilecols, (params.incrementCol < 0) and (function(a, b) return a > b end) or nil)
        end

        for _, col in ipairs(tilecols) do
            local instance = data[row][col]
            if instance then table.insert(renderer.drawtiles, instance) end
        end

        ::continue::
    end
end

--- Sets up rendering tiles for orthogonal and isometric maps.
---@param renderer table The current layer renderer
---@param layer table The layer that owns the renderer
---@param map table The current map
---@param chunk table Used with infinite maps
local function _setup_ortho_iso_tiles(renderer, layer, map, chunk)
    local startRow     = 1
    local endRow       = chunk and chunk.height or layer.height
    local incrementCol = 1
    local incrementRow = 1

    -- Determine the order to add tiles to the tile instance.
    -- The default setup is right-down.
    if map.renderorder == 'right-up' then
        startRow, endRow, incrementRow = endRow, startRow, -1
    elseif map.renderorder == 'left-down' then
        incrementCol = -1
    elseif map.renderorder == 'left-up' then
        incrementCol = -1
        startRow, endRow, incrementRow = endRow, startRow, -1
    end

    _position_tiles(renderer, layer, chunk, {
        startRow     = startRow,
        endRow       = endRow,
        incrementRow = incrementRow,
        incrementCol = incrementCol
    })
end

--- Sets up render tiles for layer.
---@param renderer table The current layer renderer
---@param layer table The layer that owns ther renderer
---@param map table The current map
---@param chunk table Used with infinite maps
local function _setup_render_tiles(renderer, layer, map, chunk)
    if map:getOrientation() == 'orthogonal' or map:getOrientation() == 'isometric' then
        _setup_ortho_iso_tiles(renderer, layer, map, chunk)
    else
        -- Hexagon maps.
        -- Note that hexagon maps in Tiled ignore the renderorder field and will always render
        -- with the 'right-down' order.
        -- TODO: Create flag that overrides hexagon map render order behaviour.

        _position_tiles(renderer, layer, chunk, {
            startRow     = 1,
            endRow       = chunk and chunk.height or layer.height,
            incrementRow = 1,
            incrementCol = 1
        })
    end
end

--- Builds reference table which holds only the tiles that need drawing for a layer.
---@param renderer table The current layer renderer
---@param layer table The layer that owns the renderer
---@param map table The current map
local function _build_render_tiles(renderer, layer, map)
    if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
            _setup_render_tiles(renderer, layer, map, chunk)
        end
    else
        _setup_render_tiles(renderer, layer, map)
    end
end

local function _collides(layer, instance, screen)
    return collision.rectRect(
        instance:getX() + instance:getOffsetX() + layer:getOffsetX(),
        instance:getY() + instance:getOffsetY() + layer:getOffsetY(),
        instance:getWidth(), instance:getHeight(),
        screen.x, screen.y, screen.width, screen.height
    )
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- This class is used to draw a tile layer when sprite batches are not available.
---@param layer table The layer that owns the renderer
---@param map table The current map
function LayerRenderer:init(layer, map)
    self.owner = layer
    self.bufferwidth = map:getTileWidth()
    self.bufferheight = map:getTileHeight()
    self.drawtiles = {}

    _build_render_tiles(self, layer, map)
end

--- Returns the map that owns the instance of the layer renderer.
---@return table map
function LayerRenderer:getOwner()
    return self.owner
end

--- Returns the width and height of the drawing buffer.
---@return number bufferwidth, number bufferheight
function LayerRenderer:getBufferDimensions()
    return self:getBufferWidth(), self:getBufferHeight()
end

--- Returns the width of the drawing buffer.
---@return number bufferwidth
function LayerRenderer:getBufferWidth()
    return self.bufferwidth
end

--- Returns the height of the drawing buffer.
---@return number bufferheight
function LayerRenderer:getBufferHeight()
    return self.bufferheight
end

--- Sets the drawing buffer width and height.
---@param bufferwidth number The width of the drawing buffer
---@param bufferheight number The height of the drawing buffer
function LayerRenderer:setBufferDimensions(bufferwidth, bufferheight)
    self:setBufferWidth(bufferwidth)
    self:setBufferHeight(bufferheight)
end

--- Sets the drawing buffer width.
---@param bufferwidth number The width of the drawing buffer
function LayerRenderer:setBufferWidth(bufferwidth)
    assert(type(bufferwidth) == "number", "setBufferWidth : param #1 must be a number type")
    self.bufferwidth = (bufferwidth > 0) and bufferwidth or 0
end

--- Sets the drawing buffer height.
---@param bufferheight number The height of the drawing buffer
function LayerRenderer:setBufferHeight(bufferheight)
    assert(type(bufferheight) == "number", "setBufferHeight : param #1 must be a number type")
    self.bufferheight = (bufferheight > 0) and bufferheight or 0
end

--- Renders the tile layer using the draw order of the map.
---@param tx number The distance the layer has translated in the x direction
---@param ty number The distance the layer has translated in the y direction
function LayerRenderer:render(tx, ty)
    local layer = self:getOwner()
    local map = layer:getMap()

    local viewW, viewH = map:getCanvas():getDimensions()
    local bufW, bufH = self:getBufferDimensions()
    local screen = {
        x      = (-tx or 0) - bufW,
        y      = (-ty or 0) - bufH,
        width  = viewW + (bufW * 2),
        height = viewH + (bufH * 2)
    }

    local offsetx, offsety = layer:getOffsets()

    for _, instance in ipairs(self.drawtiles) do
        if not _collides(layer, instance, screen) then goto continue end

        local tile
        if instance.animation then
            local gid = instance:getAnimation():getCurrentGid()
            tile = map:getTile(gid)
        else
            tile = instance:getTile()
        end

        local x, y, r, sx, sy, ox, oy = instance:getDrawCoords()
        if tile:isAtlas() then
            love.graphics.draw(tile:getImage(), tile:getQuad(), x + offsetx, y + offsety, r, sx, sy, ox, oy)
        else
            love.graphics.draw(tile:getImage(), x + offsetx, y + offsety, r, sx, sy, ox, oy)
        end

        ::continue::
    end
end

return LayerRenderer