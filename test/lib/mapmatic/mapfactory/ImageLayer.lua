
local lib = (...):gsub("mapfactory.ImageLayer$", '')
local cwd = (...):gsub("%.ImageLayer$", '') .. '.'

local utils    = require(lib .. "utils")
local Class    = require(lib .. "class")
local maputils = require(cwd .. 'maputils')

local ImageLayer = Class{__name='ImageLayer'}
local Layer

--==[[ PRIVATE METHODS ]]==--

local function _build_quad(layer)
    local image = layer:getImage()
    local repeatx, repeaty = layer:getRepeat()
    local mirrorx, mirrory = layer:getMirrored()

    local function nil_quad() layer.quad = nil end
    if not image then return nil_quad() end
    if not repeatx and not repeaty then return nil_quad() end

    local viewW, viewH = layer:getMap():getCanvas():getDimensions()
    local imgW, imgH   = image:getDimensions()

    local quadW = repeatx and viewW or imgW
    local quadH = repeaty and viewH or imgH

    layer.image:setWrap(
        repeatx and (mirrorx and "mirroredrepeat" or "repeat") or "clampzero",
        repeaty and (mirrory and "mirroredrepeat" or "repeat") or "clampzero"
    )

    layer.quad = love.graphics.newQuad(0, 0, quadW, quadH, imgW, imgH)
end

--- Loads the image file and stores it in the map cache.
---@param layer table The image layer to build
---@param map table The current map
---@param path string The path to the exported Tiled map
local function _build_image_layer(layer, map, path)
    if not (layer.image == '') then
        layer.path = utils.string.normalizePath(path .. layer.image)
        if not map:getFactory():getCacheItem(layer.path) then
            maputils.cacheImage(map:getFactory():getCache(), layer.path)
        end

        layer.image  = map:getFactory():getCacheItem(layer.path)
    else
        layer.path = ''
    end
end

--==[[ CLASS METHODS ]]==--

--- Initialize the ImageLayer object
---@param map table The current map
---@param path string The path to the exported Tiled map
---@param parent? table The parent layer that contains this layer
function ImageLayer:init(map, path, parent)
    Layer.init(self, map, path, parent)
    _build_image_layer(self, map, path)

    -- Repeat X and Repeat Y introduced in Tiled 1.8.0.
    -- Add the variables to exported Tiled maps before v1.8.0.
    self.repeatx = (self.repeatx == nil) and false or (self.repeatx == true)
    self.repeaty = (self.repeaty == nil) and false or (self.repeaty == true)

    -- mirror background image when repeated.
    -- Note: These are not a values exported by Tiled and must be set manually.
    self.mirroredx = false
    self.mirroredy = false

    _build_quad(self)
end

--- Retrieves the image used by the image layer
---@return userdata image
function ImageLayer:getImage()
    if not self:hasImage() then return end
    return self.image
end

--- Returns the quad used to draw repeating images. If the repeatx and repeaty are false, the quad will be nil.
---@return userdata quad
function ImageLayer:getQuad()
    return self.quad
end

--- Returns true if the image layer has an image loaded.
---@return boolean
function ImageLayer:hasImage()
    if ((self.image == '') or (self.image == nil)) then return false end
    return utils.love.typeOf(self.image, "Image")
end

--- Returns the width of the image layer.
---@return number width
function ImageLayer:getWidth()
    if not self:hasImage() then return 0 end

    local quad = self:getQuad()
    if not quad then return self.image:getWidth() end

    local _, _, width = quad:getViewport()
    return width
end

--- Returns the width of the image layer.
---@return number width
function ImageLayer:getHeight()
    if not self:hasImage() then return 0 end

    local quad = self:getQuad()
    if not quad then return self.image:getWidth() end

    local _, _, _, height = quad:getViewport()
    return height
end

--- Returns the repeat flags in the x and y directions.
---@return boolean repeatx, boolean repeaty
function ImageLayer:getRepeat()
    return self:getRepeatX(), self:getRepeatY()
end

--- Returns the repeat flag for the x direction.
---@return boolean repeatx
function ImageLayer:getRepeatX()
    return (self.repeatx == true)
end

--- Returns the repeat flag for the y direction.
---@return boolean repeaty
function ImageLayer:getRepeatY()
    return (self.repeaty == true)
end

--- Sets the repeat flags for both the x and y directions.
---@param repeatx boolean The repeat flag for the x direction
---@param repeaty boolean the repeat flag for the y direction
function ImageLayer:setRepeat(repeatx, repeaty)
    self.repeatx = (repeatx == true)
    self.repeaty = (repeaty == true)
    _build_quad(self)
end

--- Sets the repeat flag for the x direction.
---@param repeatx boolean The repeat flag for the x direction
function ImageLayer:setRepeatX(repeatx)
    self.repeatx = (repeatx == true)
    _build_quad(self)
end

--- Sets the repeat flag for the y direction.
---@param repeaty boolean The repeat flag for the y direction
function ImageLayer:setRepeatY(repeaty)
    self.repeaty = (repeaty == true)
    _build_quad(self)
end

--- Returns the image mirror flags for both the x and y directions.
---@return boolean mirroredx, boolean mirroredy
function ImageLayer:getMirrored()
    return self:getMirroredX(), self:getMirroredY()
end

--- Returns the image mirror flag for the x direction.
---@return boolean mirroredx
function ImageLayer:getMirroredX()
    return (self.mirroredx == true)
end

--- Returns the image mirror flag for the y direction.
---@return boolean mirroredy
function ImageLayer:getMirroredY()
    return (self.mirroredy == true)
end

--- Sets the mirror flags in both the x and y directions. If the coresponding repeat flag is set, the
--- mirror flag will mirror the image as it is repeated.
---@param mirroredx boolean The mirror flag for the x direction
---@param mirroredy boolean The mirror flag for the y direction
function ImageLayer:setMirrored(mirroredx, mirroredy)
    self.mirroredx = (mirroredx == true)
    self.mirroredy = (mirroredy == true)
    _build_quad(self)
end

--- Sets the mirror flag in the x direction. If the coresponding repeat flag is set, the
--- mirror flag will mirror the image as it is repeated.
---@param mirroredx boolean The mirror flag for the x direction
function ImageLayer:setMirroredX(mirroredx)
    self.mirroredx = (mirroredx == true)
    _build_quad(self)
end

--- Sets the mirror flag in the y direction. If the coresponding repeat flag is set, the
--- mirror flag will mirror the image as it is repeated.
---@param mirroredy boolean The mirror flag for the y direction
function ImageLayer:setMirroredY(mirroredy)
    self.mirroredy = (mirroredy == true)
    _build_quad(self)
end

--- Renders the image layer.
function ImageLayer:render(tx, ty)
    local image = self:getImage()
    if (image == nil) or (image == '') then return end

    local offsetx, offsety = self:getOffsets()
    local repeatx, repeaty = self:getRepeat()
    local mirrorx, mirrory = self:getMirrored()
    local imgw, imgh       = image:getDimensions();

    if repeatx or repeaty then

        local x       = repeatx and 0 or tx
        local y       = repeaty and 0 or ty
        local viewx   = repeatx and -tx or 0
        local viewy   = repeaty and -ty or 0

        local quad = self:getQuad()
        local _, _, vieww, viewh = quad:getViewport()

        quad:setViewport(viewx, viewy, vieww, viewh, imgw, imgh)

        love.graphics.push()
        love.graphics.origin()

        love.graphics.draw(
            image, quad,
            x + offsetx, y + offsety, 0,
            repeatx and 1 or (mirrorx and -1 or 1),
            repeaty and 1 or (mirrory and -1 or 1),
            repeatx and 0 or (mirrorx and vieww or 0),
            repeaty and 0 or (mirrory and viewh or 0)
        )

        love.graphics.pop()
    else
        love.graphics.draw(image, offsetx, offsety, 0,
            mirrorx and -1 or 1,
            mirrory and -1 or 1,
            mirrorx and imgw or 0,
            mirrory and imgh or 0
        )
    end
end

--==========================
--==[[ MODULE METHODS ]]==--
--==========================

return function(parentClass)
    assert(utils.class.isClass(parentClass), "ImageLayer : parentClass not a valid class")
    assert(utils.class.typeOf(parentClass, "Layer"), "ImageLayer : parentClass must be a Layer class")

    ImageLayer:include(parentClass)
    Layer = parentClass
    return ImageLayer
end