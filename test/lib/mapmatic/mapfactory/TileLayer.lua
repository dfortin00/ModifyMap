local lib = (...):gsub("mapfactory.TileLayer$", '')
local cwd = (...):gsub("%.TileLayer$", '') .. '.'

local utils         = require(lib .. "utils")
local Class         = require(lib .. "class")
local TileInstance  = require(cwd .. 'TileInstance')
local LayerRenderer = require(cwd .. 'LayerRenderer')

local TileLayer = Class{__name='TileLayer'}
local Layer

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Returns the number of tiles wide for an infinite map.
---@param chunks table The chunks array for the tile layer
---@return number width
local function _get_chunks_width(chunks)
    if #chunks == 0 then return 0 end

    chunks = utils.table.copy(chunks)
    table.sort(chunks, function(a, b)
        return a.x < b.x
    end)

    local xPos = chunks[1].x
    local width = chunks[1].width

    for i = 2, #chunks do
        if not (chunks[i].x == xPos) then
            width = width + chunks[i].width
            xPos = chunks[i].x
        end
    end

    return width
end

--- Returns the number of tiles high for an infinite map.
---@param chunks table The chunks array for the tile layer
---@return number height
local function _get_chunks_height(chunks)
    if #chunks == 0 then return 0 end

    chunks = utils.table.copy(chunks)
    table.sort(chunks, function(a, b)
        return a.y < b.y
    end)

    local yPos = chunks[1].y
    local height = chunks[1].height

    for i = 2, #chunks do
        if not (chunks[i].y == yPos) then
            height = height + chunks[i].height
            yPos = chunks[i].y
        end
    end

    return height
end

--- Create new TileInstance objects from global tile data.
---@param layer table The current tile layer
---@param map table The current map
---@param chunk? table A map chunk taken from an infinite map
local function _create_tile_instances(layer, map, chunk)
    local i = 1
    local tilemap = {}
    local data = chunk and chunk.data or layer.data
    local mapW = chunk and chunk.width or layer:getWidth()
    local mapH = chunk and chunk.height or layer:getHeight()

    for row = 1, mapH do
        tilemap[row] = {}
        for col = 1, mapW do
            local gid = data[i]
            if gid > 0 then
                tilemap[row][col] = TileInstance(map, layer, col, row, gid, chunk)
            end
            i = i + 1
        end
    end

    if chunk then chunk.data = tilemap else layer.data = tilemap end
end


--- Replace each gid value in the raw tile data with a new tile instance.
---@param layer table The current layer
---@param map table The current map
local function _build_tile_data(layer, map)
    -- Chunks occur when map is infinite.
    if layer.chunks then
        layer.chunks.width = _get_chunks_width(layer.chunks)
        layer.chunks.height = _get_chunks_height(layer.chunks)

        for _, chunk in ipairs(layer.chunks) do
            _create_tile_instances(layer, map, chunk)
        end
    else
        _create_tile_instances(layer, map)
    end
end

--- Checks the tiles in an animation to make sure none of them are larger than the map tile size.
---@param layer table The current layer
---@param map table The current map
---@param tile table The first tile in the animation sequence
---@return boolean
local function _check_animation_tiles(layer, map, tile)
    local tileW = map:getTileWidth()
    local tileH = map:getTileHeight()

    for _, animation in ipairs(tile.animation) do
        local maptile = map:getTile(animation.gid)
        if (maptile:getWidth() > tileW) or (maptile:getHeight() > tileH) then
            layer.usebatchdraw = false
            return false
        end
    end

    return true
end

--- Checks whether all tiles in the layer have a width and height less than or equal to the
--- width and height of the map tile size.
---@param layer table The current layer
---@param map table The current map
---@param data table The layer tile instances
---@return boolean
local function _check_tile_dimensions(layer, map, data)
    local tileW = map:getTileWidth()
    local tileH = map:getTileHeight() * ((map:getOrientation() == 'isometric') and 2 or 1)

    for _, row in pairs(data) do
        for _, instance in pairs(row) do
            local tile = instance:getTile()
            if (tile:getWidth() > tileW) or (tile:getHeight() > tileH) then
                layer.usebatchdraw = false
                return false
            end

            -- Animation frames for tilesets must have same tile size, but collection tiles can vary in size.
            -- TODO: Correction. Tile animations that have tiles with different sizes will always scale to the
            -- size of the first tile in the animation. Need to fix this with the renderer first before removing
            -- this test.
            if (tile:getImageType() == 'collection') and (tile:getAnimation()) then
                if not _check_animation_tiles(layer, map, tile) then return false end
            end
        end
    end

    return true
end

--- Checks if any tiles on the layer are larger than the map tile size, and disables sprite batches if there are.
---@param layer table The current layer
---@param map table The current map
local function _check_batch_draw_eligibility(layer, map)
    if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
            if not _check_tile_dimensions(layer, map, chunk.data) then return end
        end
    else
        _check_tile_dimensions(layer, map, layer.data)
    end
end

--- Adds tile instances to the appropriate sprite batch objects.
---@param layer table The current layer
---@param row number The row for the tile instance
---@param col number The col for the tile instance
---@param chunk? table A map chunk taken from an infinite map
local function _update_sprite_batch(layer, col, row, chunk)
    local data = chunk and chunk.data or layer.data
    local instance = data[row][col]

    if not instance then return end

    local tile    = instance:getTile()
    local isAtlas = tile:isAtlas()
    local index   = tile:getTileSetIndex()
    local image   = tile:getImage()

    local batches
    local size

    if chunk then
        batches = chunk.batches
        size = chunk.width * chunk.height
    else
        batches = layer.batches
        size = layer:getWidth() * layer:getHeight()
    end

    local batch

    if isAtlas then
        batches[index] = batches[index] or love.graphics.newSpriteBatch(image, size)
        batch = batches[index]
    else
        local tileid = tile:getId()
        batches[index] = batches[index] or {}
        batches[index][tileid] = batches[index][tileid] or love.graphics.newSpriteBatch(image, size)
        batch = batches[index][tileid]
    end

    if batch then
        instance.batch = batch
        if isAtlas then
            instance.batchid = batch:add(tile:getQuad(), instance:getDrawCoords())
        else
            instance.batchid = batch:add(instance:getDrawCoords())
        end
    end
end


--- Sets up tile instances for orthogonal and isometric maps.
---@param layer table The current layer
---@param map table The current map
---@param chunk? table A map chunk taken from an infinite map
local function _setup_orth_iso_batches(layer, map, chunk)
    local startX     = 1
    local startY     = 1
    local endX       = chunk and chunk.width or layer:getWidth()
    local endY       = chunk and chunk.height or layer:getHeight()
    local incrementX = 1
    local incrementY = 1

    -- Determine the order to add tiles to the sprite batch.
    -- The default setup is right-down.
    if map.renderorder == 'right-up' then
        startY, endY, incrementY = endY, startY, -1
    elseif map.renderorder == 'left-down' then
        startX, endX, incrementX = endX, startX, -1
    elseif map.renderorder == 'left-up' then
        startX, endX, incrementX = endX, startX, -1
        startY, endY, incrementY = endY, startY, -1
    end

    for row = startY, endY, incrementY do
        for col = startX, endX, incrementX do
            _update_sprite_batch(layer, col, row, chunk)
        end
    end
end

--- Sets up tile instances for hexagon based maps.
---@param layer table The current layer
---@param map table The current map
---@param chunk? table A map chunk taken from an infinite map
local function _setup_hexagon_batches(layer, map, chunk)
    local width = (chunk and chunk.width or layer:getWidth())
    local height = (chunk and chunk.height or layer:getHeight())

    if map.staggeraxis == 'y' then
        for row = 1, height do
            for col = 1, width do
                _update_sprite_batch(layer, col, row, chunk)
            end
        end
    else
        local i = 0
        local xStart  = (map.staggerindex == 'odd') and 1 or 2
        local mapsize = width * height

        while i < mapsize do
            for y = 1, height + 0.5, 0.5 do
                local y = math.floor(y)

                for x = xStart, width, 2 do
                    i = i + 1
                    _update_sprite_batch(layer, y, x, chunk)
                end

                xStart = (xStart == 1) and 2 or 1
            end
        end
    end
end

--- Sets up the tile instances for the map layer.
---@param layer table The current layer
---@param map table The current map
---@param chunk? table A map chunk taken from an infinite map
local function _setup_tile_sprite_batches(layer, map, chunk)
    if chunk then
        chunk.batches = {}
    else
        layer.batches = {}
    end

    if map:getOrientation() == 'orthogonal' or map:getOrientation() == 'isometric' then
        _setup_orth_iso_batches(layer, map, chunk)
    else
        _setup_hexagon_batches(layer, map, chunk)
    end
end

--- Batch together tiles in a SpriteBatch to reduce render operations and improve performance.
---@param layer table The current layer
---@param map table The current map
local function _build_tile_sprite_batches(layer, map)
    if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
            _setup_tile_sprite_batches(layer, map, chunk)
        end
    else
        _setup_tile_sprite_batches(layer, map)
    end
end

--- Renders a tile layer using sprite batches.
---@param layer table The current layer
local function _render_tile_layer(layer)
    if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
            -- TODO: Check if chunks with tile collections need to have draw operations separated like layers.batch below.
            for _, batch in pairs(chunk.batches) do
                love.graphics.draw(batch, 0, 0)
            end
        end
    else
        for _, batch in pairs(layer.batches) do
            if type(batch) == 'table' then
                -- SpriteBatches for collections.
                for _, cbatch in pairs(batch) do
                    love.graphics.draw(cbatch, layer:getDrawCoords())
                end
            else
                love.graphics.draw(batch, layer:getDrawCoords())
            end
        end
    end
end

--- Renders animations for tile collections.
---@param layer table The current layer
---@param map table The current map
local function _render_tile_collection_animations(layer, map)
    if not map or not map.animations[layer:getLayerPath()] then return end

    for _, item in ipairs(map.animations[layer:getLayerPath()]) do
        local gid       = item:getAnimation():getCurrentGid()
        local frametile = map:getTile(gid)

        if (item:type() == 'TileInstance') and not frametile:isAtlas() then
            local offsetx, offsety = layer:getOffsets()
            local x, y, r, sx, sy, ox, oy = item:getDrawCoords()
            love.graphics.draw(frametile:getImage(), x + offsetx, y + offsety, r, sx, sy, ox, oy)
        end
    end
end

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Initializes a tile layer object from the exported map data.
---@param map table The current map
---@param parent? table The parent group folder containing this layer
function TileLayer:init(map, parent)
    Layer.init(self, map, '', parent)

    self.usebatchdraw = true

    _build_tile_data(self, map)
    _check_batch_draw_eligibility(self, map)

    if self.usebatchdraw then
        _build_tile_sprite_batches(self, map)
    else
        self.renderer = LayerRenderer(self, map)
    end
end

--- Determines whether or not sprite batches are being used to draw the layer.
---@return boolean
function TileLayer:usesBatchDraw()
    return (self.usebatchdraw == true)
end

--- Overrides the default sprite batch draw logic.
---@param usebatches boolean True - use sprite batches, False - render each tile individually
function TileLayer:setBatchDraw(usebatches)
    usebatches = (usebatches == true)
    if self.usebatchdraw == usebatches then return end
    self.usebatchdraw = usebatches

    if usebatches then
        _build_tile_sprite_batches(self, self:getMap())
        self.renderer = nil
    else
        if self.chunks then
            for _, chunk in ipairs(self.chunks) do
                chunk.batches = nil
            end
        else
            self.batches = nil
        end

        self.renderer = LayerRenderer(self, self:getMap())
    end
end

--- Returns a handle to the layer renderer used when batch drawing is disabled.
---@return table renderer
function TileLayer:getRenderer()
    if self:usesBatchDraw() then return end
    return self.renderer
end

--- Retrieves the tile instance located at the coordinates, or nil if no tile is found.
--- Tile coordinates are zero-based, which is the same as the Tiled map editor.
---@param row number The layer row
---@param col number The layer column
---@return table | nil tileInstance
function TileLayer:getTileInstance(col, row)
    assert(col and row, "getTileInstance : must include both col and row parameters to locate instance")

    -- Tiled used zero-based index, but Lua uses one-based index.
    col = col + 1
    row = row + 1

    if self.chunks then
        local data
        local datacol = 0
        local datarow = 0

        for _, chunk in ipairs(self.chunks) do
            if (col > chunk.x) and (row > chunk.y) then
                data = chunk.data
                datacol = col - chunk.x
                datarow = row - chunk.y
            else
                break
            end
        end

        if not data or not data[datarow] then return end
        return data[datarow][datacol]
    else
        if not self.data[row] then return end
        return self.data[row][col]
    end
end

--- Returns a flat array of all tile instances in the order they are drawn.
---@return table instances
function TileLayer:getTileInstances()
    local instances = {}
    for _, row in pairs(self.data) do
        local keys = utils.table.keys(row)
        for col = 1, #keys do
            table.insert(instances, row[keys[col]])
        end
    end

    return instances
end

--- Returns the the width and height of the tile layer in number of tiles. For regular maps,
--- the width and height of the tile layer will match the width and height of the map. However,
--- infinite maps will calculate the width and height of all the layer chunks together.
---@return number width, number height
function TileLayer:getDimensions()
    if self.chunks then
        return self.chunks.width, self.chunks.height
    else
        return self.width, self.height
    end
end

--- Returns the number of tiles wide for the tile layer. For regular maps, the width the tile layer
--- will match the width of the map. However, infinite maps will calculate the width of all the layer
--- chunks together.
---@return number width
function TileLayer:getWidth()
    if self.chunks then
        return self.chunks.width
    else
        return self.width
    end
end

--- Returns the number of tiles high for the tile layer. For regular maps, the height the tile layer
--- will match the height of the map. However, infinite maps will calculate the height of all the layer
--- chunks together.
---@return number height
function TileLayer:getHeight()
    if self.chunks then
        return self.chunks.height
    else
        return self.height
    end
end

--- Default render method for tile layers.
function TileLayer:render(tx, ty)
    if self.usebatchdraw then
        _render_tile_layer(self)
        _render_tile_collection_animations(self, self:getMap())
    else
        self.renderer:render(tx, ty)
    end
end

--==========================
--==[[ MODULE METHODS ]]==--
--==========================

return function(parentClass)
    assert(utils.class.isClass(parentClass), "TileLayer : parentClass not a valid class")
    assert(utils.class.typeOf(parentClass, "Layer"), "TileLayer : parentClass must be a Layer class")

    TileLayer:include(parentClass)
    Layer = parentClass
    return TileLayer
end
