---@diagnostic disable: unused-label


local _love = {}

-- Require all .lua files in the provided path. The optional pattern parameter allows the
-- user to filter filenames. This method searches for files in subfolders as well.
function _love.requirePath(path, pattern)
    for _, name in ipairs(love.filesystem.getDirectoryItems(path)) do
        local filetype = love.filesystem.getInfo(path .. '/' .. name)
        if filetype.type == 'directory' then
            _love.requirePath(path .. '/' .. name, pattern)
        else
            if pattern and not name:match(pattern) then goto continue end

            local path = (path:gsub("/", "."))
            local file = (name:gsub(".lua", ""))
            require (path .. '.' .. file)
        end
        ::continue::
    end
end

--[[ Returns the object type. If the object is a LOVE2D object, the object:type() will be called. ]]
function _love.type(object)
    local type_o = type(object)

    if ((type_o == 'table') or (type_o == 'userdata')) and object.type then
        type_o = object:type()
    end

    return type_o
end

--[[ Returns true if the object is a type of the specified LOVE2D object. ]]
function _love.typeOf(object, name)
    local type_o = type(object)
    if not (type_o == "userdata") or not object.typeOf or not (type(object.typeOf) == "function") then
        return false
    end
    return object:typeOf(name)
end

return _love