
local _string = {}

--[[
    Cleans up path string by removing any // or /./, and clipping everything up to and including /../ directories.
    e.g. 'tiled/../assets/./tileset.png' becomes 'assets/tileset.png'
    Note: This function only works with Windows style directory structures.
]]
function _string.normalizePath(path)
    -- SEP = separator
    local np_gen1 = '[^SEP]+SEP%.%.SEP?'
    local np_gen2 = 'SEP+%.?SEP'

    local np_pat1 = np_gen1:gsub('SEP', '/')
    local np_pat2 = np_gen2:gsub('SEP', '/')
    local k

    -- np_pat2 : /+%.?/
    -- Remove // or /./ patterns from path.
    repeat
        path, k = path:gsub(np_pat2, '/', 1)
    until (k == 0)

    -- np_pat1 : [^/]+/%.%./?
    -- Remove anything up to and including /../ from path.
    repeat
        path, k = path:gsub(np_pat1, '', 1)
    until (k ==0)

    if path == '' then path = '.' end

    return path
end

--[[
    Splits a path string into three parts: [1] path, [2] filename, [3] extension.
    If the path or extension are missing, they will be returned as an empty string.
]]
function _string.splitPath(input)
    if not(type(input) == 'string') then error("<utils>.string.splitPath: param #1 must be a string", 2) end

    -- Determine if this is just a file name without the path.
    if not input:find('\\') and not input:find('/') then
        local extension = input:match('([^%.]+)$')
        if extension == input then extension = '' end
        return '', input,  extension
    end

    -- Parse the full path including the filename and extension.
    local parts
    if input:find('\\') then
        parts = {input:match('(.-)([^\\]-([^\\%.]+))$')} -- Windows
    else
        parts = {input:match('(.-)([^/]-([^/%.]+))$')}   -- Linux
    end
    if parts[2] == parts[3] then parts[3] = '' end

    return unpack(parts)
end

return _string