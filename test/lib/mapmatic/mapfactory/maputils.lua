local lib = (...):gsub("mapfactory.maputils$", '')
local utils = require(lib .. "utils")

local _maputils = {}

--===========================
--==[[ PRIVATE METHODS ]]==--
--===========================

--- Callback function used by the LOVE2D ImageData:mapPixel function.
--- Removes any pixels that match the specified RGBA color in the image by scanning each pixel
--- in the entire image. If the pixel color at the current iteration matches the transparent mask,
--- then the color is returned with alpha channel turned off, otherwise the color is ignored.
---@param r number Red channel of transparent pixel color
---@param g number Green channel of transparent pixel color
---@param b number Blue channel of transparent pixel color
---@param a number Alpha channel of transparent pixel color
---@return number r, number g, number b, number a
local function _transparent_pixel_function(_, _, r, g, b, a)
    local mask = _maputils._TC

    if r == mask[1] and g == mask[2] and b == mask[3] then
        return r, g, b, 0
    end

    return r, g, b, a
end

--- Determins the relative distance between two vectors.
---@param a table Vector A
---@param b table Vector B
---@return number distance
local function _vector_distance(a, b)
    local x = a.x - b.x
    local y = a.y - b.y
    return x * x + y * y
end

--- Calculates the number of segments required to convert an ellipse into a polygon.
---@param segments integer
---@param x number The x-coordinate of the center point of the ellipse
---@param y number The y-coordinate of the center point of the ellipse
---@param w number Ellipse width
---@param h number Ellipse height
---@return integer segments
local function _calc_segments(segments, x, y, w, h)
    segments = segments or 64
    local vertices = {}

    local v = {1, 2, math.ceil(segments * 0.25 - 1), math.ceil(segments * 0.25)}
    local m = (love and love.physics) and love.physics.getMeter() or 32

    for _, i in ipairs(v) do
        local angle = (i / segments) * math.pi * 2
        local px = x + w * 0.5 + math.cos(angle) * w * 0.5
        local py = y + h * 0.5 + math.sin(angle) * h * 0.5

        table.insert(vertices, {x = px / m, y = py / m})
    end

    local dist1 = _vector_distance(vertices[1], vertices[2])
    local dist2 = _vector_distance(vertices[2], vertices[4])

    -- Box2D threshold
    if dist1 < 0.0025 or dist2 < 0.0025 then
        return _calc_segments(segments - 2, x, y, w, h)
    end

    return segments
end

--- Converts screen coordinates into an isometric tile location (without flooring).
---@param map table The current map
---@param x number The x-coordinate in pixels on the screen
---@param y number The y-coordinate in pixels on the screen
---@return number tileCol, number tileRow
local function _isometric_tile_coordinates(map, x, y)
    local tileW = map.tilewidth
    local tileH = map.tileheight
    local halfW = tileW * 0.5
    local halfH = tileH * 0.5

    local originX = map.width * halfW

    x = x - originX - map.offsetx
    y = y - map.offsety

    return
        (x / halfW + y / halfH) * 0.5,
        (y / halfH - x / halfW) * 0.5
end

--- Apply tile transformations to tiles.
---@param tile table The current map tile to transform
---@param flipX boolean The tile should be flipped horizontally
---@param flipY boolean The tile should be flipped vertically
---@param flipD boolean The tile should be flipped anti-diagonally
local function _transform_tile(tile, flipX, flipY, flipD)
    if flipX then
        if flipY and flipD then
            tile.rotation = math.rad(-90)
            tile.sy = -1
        elseif flipY then
            tile.sx = -1
            tile.sy = -1
        elseif flipD then
            tile.rotation = math.rad(90)
        else
            tile.sx = -1
        end
    elseif flipY then
        if flipD then
            tile.rotation = math.rad(-90)
        else
            tile.sy = -1
        end
    elseif flipD then
        tile.rotation = math.rad(90)
        tile.sy = -1
    end
end

--======================
--==[[ PUBLIC API ]]==--
--======================

--- The Terrain builder in Tiled can sometimes minimize the number of build patterns by setting the
--- Allowed Transformations flags (flip x, flip y, rotate) on the Tileset editor. This will in turn set
--- certain bits on the last byte of the 32-bit gid. These flags are also be set when tile objects on an
--- object layer are flipped using the Flipping property.
---@param map table The current map
---@param gid number The GID of the tile
---@return table tile
function _maputils.buildTransformedTile(map, gid)
    local flippedHorzFlag     = 0x80000000
    local flippedVertFlag     = 0x40000000
    local flippedAntiDiagFlag = 0x20000000

    local flipX = false
    local flipY = false
    local flipD = false

    local realgid = gid

    if realgid >= flippedHorzFlag then
        realgid = realgid - flippedHorzFlag
        flipX = true
    end
    if realgid >= flippedVertFlag then
        realgid = realgid - flippedVertFlag
        flipY = true
    end
    if realgid >= flippedAntiDiagFlag then
        realgid = realgid - flippedAntiDiagFlag
        flipD = true
    end

    local tile = utils.table.copy(map.tiles[realgid])
    tile.gid = gid

    _transform_tile(tile, flipX, flipY, flipD)

    map.tiles[gid] = tile
    return map.tiles[gid]
end

--- Adds a tile or tileset image to the MapFactory cache.
---@param cache table The global image cache table
---@param path string The path to the image file
---@param image? userdata A pre-loaded LOVE2D Image
function _maputils.cacheImage(cache, path, image)
    image = image or love.graphics.newImage(path)
    image:setFilter('nearest', 'nearest')
    cache[path] = image
end

-- More details on converting between screen coordinates and isometric coordinates and vice-versa.
-- http://clintbellanger.net/articles/isometric_math/

--- Convert isometric pixel coordinate into Cartesian pixel coordinate.
---@param map table The current map
---@param x number The x-coordinate inside the isometric map
---@param y number The y-coordinate inside the isometric map
---@return number x, number y
function _maputils.convertIsometricToScreen(map, x, y)
    assert(map.orientation == "isometric", "convertIsometricToScreen : map orientation must be 'isometric'")

    local tileW   = map.tilewidth
    local tileH   = map.tileheight

    local tileCol = x / tileW
    local tileRow = y / tileH
    local halfW = tileW * 0.5
    local halfH = tileH * 0.5

    -- The x-coordinate of the top corner of the isometric map.
    local originX = map.width * halfW

    return
        (tileCol - tileRow) * halfW + originX + map.offsetx,
        (tileCol + tileRow) * halfH + map.offsety
end

--- Convert screen coordinates into isometric map coordinates.
---@param map table The current map
---@param x number The x-coordinate on the screen
---@param y number The y-coordinate on the screen
---@return number mapX, number mapY
function _maputils.convertScreenToIsometric(map, x, y)
    assert(map.orientation == "isometric", "convertScreenToIsometric : map orientation must be 'isometric'")
    local tileCol, tileRow = _isometric_tile_coordinates(map, x, y)
    return (tileCol * map.tilewidth), (tileRow * map.tileheight)
end

--- Determines which isometric tile contains the provided screen coordinate.
---@param map table The current map
---@param x number The x-coordinate on the screen
---@param y number The y-coordinate on the screen
---@return number tileCol, number tileRow
function _maputils.convertScreenToIsometricTile(map, x, y)
    assert(map.orientation == "isometric", "convertScreenToIsometricTile : map orientation must be 'isometric'")
    local tileCol, tileRow = _isometric_tile_coordinates(map, x, y)
    return math.floor(tileCol), math.floor(tileRow)
end

--- Convert a Tiled ellipse object into a LOVE2D polygon.
---@param x number The x-coordinate of the top left corner of the imaginary rectangle that surrounds the ellipse
---@param y number The y-coordinate of the top left corner of the imaginary rectangle that surrounds the ellipse
---@param w number The horizontal diameter of the ellipse
---@param h number The vertical diameter of the ellipse
---@param numSegments? number The total number of vertices the final polygon should contain
---@return table polygon
function _maputils.convertEllipseToPolygon(x, y, w, h, numSegments)
    local segments = _calc_segments(numSegments, x, y, w, h)
    local vertices = {}

    -- Insert the center point into the first element of the list.
    table.insert(vertices, {x = x + w * 0.5, y = y + h * 0.5})

    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local px = x + w * 0.5 + math.cos(angle) * w * 0.5
        local py = y + h * 0.5 + math.sin(angle) * h * 0.5

        table.insert(vertices, {x = px, y = py})
    end

    return vertices
end

--- Translates a table of vertices into a flat array of x,y coordinates.
---@param t table Array of tables containing xy coordinates for each vertex in the polygon
---@return table vertices
function _maputils.flattenVertexTable(t)
    local vertices = {}
    for _, v in ipairs(t) do
        table.insert(vertices, v.x)
        table.insert(vertices, v.y)
    end

    return vertices
end

--- Decompress and decode tile layer data.
---@param data string Uncompressed data string (must be base64 encoded)
---@param compressionType? string Either 'gzip' or 'zlib'
---@return table mapData
function _maputils.getDecompressedData(data, compressionType, w, h)
    local ffi = require('ffi')

    data = love.data.decode('string', 'base64', data)

    if compressionType then
        data = love.data.decompress('string', compressionType, data)
    end

    local decoded = ffi.cast('uint32_t*', data)
    local mapData = {}
	for i = 0, data:len() / ffi.sizeof('uint32_t') do
		table.insert(mapData, tonumber(decoded[i]))
	end

    -- Trim any excess data table entries that might have been added during
    -- C-string conversions or data decompression.
    if w and h and (#mapData > (w * h)) then
        mapData = utils.array.slice(mapData, 1, w * h)
    end

    return mapData
end

--- Loads the image and fixes transparency (if it exists) for tilesets.
---@param tileset table Tileset containing image information
---@param path string Path where the image file can be located
function _maputils.loadImage(tileset, path)
    local data = love.image.newImageData(path)
    tileset.image = love.graphics.newImage(data)

    if tileset.transparentcolor then
        _maputils._TC = utils.colors.toNorm(color.hex(tileset.transparentcolor))
        data:mapPixel(_transparent_pixel_function)
        tileset.image = love.graphics.newImage(data)
    end
end

--- Rotates a vertex about a point.
---@param map table The current map
---@param vertex table The x,y coordinate of a single vertex
---@param x number The x coordinate to rotate the polygon about
---@param y number The y coordinate to rotate the polygon about
---@param cos number The pre-calculated cosine value for the rotation
---@param sin number The pre-calculated sine value for the rotations
---@param oy? number The origin point of the object in the y axis
---@return number newX, number newY
function _maputils.rotateVertex(map, vertex, x, y, cos, sin, oy)
    if map.orientation == 'isometric' then
        x, y = _maputils.convertIsometricToScreen(map, x, y)
        vertex.x, vertex.y = _maputils.convertIsometricToScreen(map, vertex.x, vertex.y)
    end

    -- Translate vertex back to origin.
    vertex.x = vertex.x - x
    vertex.y = vertex.y - y

    -- Rotate about origin
    local newX = cos * vertex.x - sin * vertex.y
    local newY = sin * vertex.x + cos * vertex.y - (oy or 0)

    --Restore the translation
    vertex.x = newX + x
    vertex.y = newY + y

    return vertex
end

return _maputils
