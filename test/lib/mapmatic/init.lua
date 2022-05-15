local path = (...):gsub("/", "."):gsub("\\", ".") .. '.'
local factory = require(path .. "mapfactory")
return factory