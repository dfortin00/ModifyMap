local lib = (...):gsub("mapfactory.TileAnimation$", '')

local utils   = require(lib .. "utils")
local Class   = require(lib .. "class")

local TileAnimation = Class{__name='TileAnimation'}

--=========================
--==[[ CLASS METHODS ]]==--
--=========================

--- Creates an instance of the animation sequence for a tile. Note: The array elements of this class table
--- contain the individual frames of animation.
---@param tile table The tile or tile instance that contains the animation
function TileAnimation:init(tile)
    local firstgid = tile:getTileSet():getFirstGid()

    self.frame = 1
    self.timer = 0
    self.looping = true
    self.playing = true
    self.speedfactor = 1

    for _, frame in ipairs(self) do
        frame.gid = frame.tileid + firstgid
    end
end

--- Returns the current frame in the animation.
---@return integer frame
function TileAnimation:getCurrentFrame()
    return self[self.frame]
end

--- Sets the current frame for the animation.
---@param frame integer The frame to skip to.
function TileAnimation:setCurrentFrame(frame)
    self.frame = utils.math.clamp(frame, 1, #self)
end

--- Returns the number of frames in the animation.
---@return integer numframes
function TileAnimation:getNumFrames()
    return #self
end

--- Returns the tile gid of the current frame of the animation.
---@return integer gid
function TileAnimation:getCurrentGid()
    return self[self.frame].gid
end

--- Returns the current speed factor for the animation.
---@return integer speedfactor
function TileAnimation:getSpeedFactor()
    return self.speedfactor
end

--- Sets the speed factor for the animation.
---@param factor number The factor to multiply the animation speed
function TileAnimation:setSpeedFactor(factor)
    self.speedfactor = math.max(0, factor)
end

--- Return true if the animation loops.
---@return boolean
function TileAnimation:isLooping()
    return (self.looping == true)
end

--- Sets the animation loop flag.
---@param loop boolean Loop flag
function TileAnimation:setLooping(loop)
    if loop == nil then return end
    self.looping = (loop == true)
end

--- Returns true if the animation is currently running.
---@return boolean
function TileAnimation:isPlaying()
    return (self.playing == true)
end

--- Starts the animation from the current frame.
function TileAnimation:play()
    self.playing = true
end

--- Pauses the animation but does not reset the frame index.
function TileAnimation:pause()
    self.playing = false
end

--- Stops the animation and resets the frame index back to the first frame.
function TileAnimation:stop()
    self.playing = false
    self.frame = 1
end

--- Advances the animation up by one frame if playing, and loops if loop flag set.
---@param dt number Delta time
function TileAnimation:update(dt)
    if not self.playing then return end
    self.timer = self.timer + dt * 1000 * self:getSpeedFactor()

    local duration = tonumber(self[self.frame].duration)
    while self.timer > duration do
        self.timer = self.timer - duration
        self.frame = self.frame + 1

        if self.frame > #self then
            if self.looping then
                self.frame = 1
            else
                self.playing = false
                return
            end
        end
    end
end

return TileAnimation