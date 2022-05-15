local lib = (...):gsub('utils.utils_params$', '')
local Class = require(lib .. "class")

local __ParamChecker = Class{__name = 'ParamChecker'}

-- Main module.
local _params = setmetatable({}, {
    __call = function(_, ...) return __ParamChecker(...) end
})

-- https://gist.github.com/jrus/3197011
math.randomseed(math.floor(os.clock()*1E11))
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local __NIL_VALUE = '{$__nil__$}_' .. uuid()

--[[ Private Method ]]
--[[ Convert an array into a string. ]]
local function _join(t, separator)
    local temp = {}

    for i = 1, t.n or #t do
        if t[i] then temp[#temp + 1] = tostring(t[i]) end
    end

    if not next(temp) then temp = {'nil'} end

    return table.concat(temp, separator)
end

-- Since testing self.param for 'nil' is used to check whether it has been initialized inside the class, there
-- has to be different way to indicate the parameter passed in is nil.

--[[ Private Method ]]
--[[ Formats the error message. ]]
local function _format(self, message)
    local method = (self._methodName and self._methodName or '')
    local name = (self._paramName and ("'"..self._paramName.."'") or ('param #' .. self._paramNum))
    local paramNum = ('param #' .. self._paramNum)

    message = message:gsub('{$method}', method)
    message = message:gsub('{$method:}', method..(self._methodName and ': ' or ''))
    message = message:gsub('{$name}', name)
    message = message:gsub('{$paramNum}', paramNum)

    return message
end

local function _is_printable_type(value)
    return ((value == 'number') or (value == 'string') or (value == 'boolean') or (value == 'nil'))
end

local function _tables_equal(actual, expected)
    local type_a, type_e = type(actual), type(expected)

    if not (type_a == type_e) then return false end
    if not (type_a == 'table') or not (type_e == 'table') then return actual == expected end

   -- as well as tables which have the metamethod __eq
    local mt = getmetatable(actual)
    if mt and mt.__eq then return actual == expected end

    for k1, v1 in pairs(actual) do
        local v2 = expected[k1]
        if v2 == nil or not _tables_equal(v1, v2) then return false end
    end

    for k2, v2 in pairs(expected) do
        local v1 = actual[k2]
        if v1 == nil or not _tables_equal(v1, v2) then return false end
    end

    return true
end

--[[ Private Method ]]
--[[ Checks if the provided value exists inside the table. ]]
local function _table_contains(t, value)
    local type_v = type(value)
    for i = 1, t.n or #t do
        if type_v == 'table' then
            if _tables_equal(t[i], value) then return true end
        else
            if (t[i] == value) then return true end
        end
    end

    return false
end

--[[
    ParamChecker Class
]]

function __ParamChecker:init(methodName, errorLevel)
    self._paramNum = 0
    self._methodName = methodName
    self._errorLevel = errorLevel or 3
    self._ifNotNil = false
end

function __ParamChecker:start(param, paramNum, paramName)
    self._actual = (param == nil) and __NIL_VALUE or param
    self._ifNotNil = false

    if paramNum and (type(paramNum) == 'number') and paramNum > 0 then
        self._paramNum = paramNum
    else
        self._paramNum = self._paramNum + 1
    end

    if not paramName or not (type(paramName) == 'string') then
        self._paramName = nil
    else
        self._paramName = paramName
    end

    return self
end

function __ParamChecker:number(paramNum)
    if (self._actual == nil) then return self end
    if paramNum and not (type(paramNum) == 'number') then return self end
    if paramNum and paramNum > 0 then
        self._paramNum = paramNum
    end
    return self
end

function __ParamChecker:name(paramName)
    if (self._actual == nil) then return self end
    if not paramName or not (type(paramName) == 'string') then return self end
    self._paramName = paramName
    return self
end

function __ParamChecker:methodName(methodName)
    if not methodName or not (type(methodName) == 'string') then return self end
    self._methodName = methodName
    return self
end

function __ParamChecker:errorLevel(level)
    if not level or not (type(level) == 'number') then return self end
    self._errorLevel = level
    return self
end

--[[
    Only perform proceeding checks in the chain if the self._actual is not a __NIL_VALUE. This allows checks
    to occur on parameters that are optional, and don't always need to be passed in. This will be dismissed the
    next time the start() method is called.
]]
function __ParamChecker:ifNotNil()
    self._ifNotNil = true
    return self
end

--[[
    Parameter Checks
]]

--[[ Throws an error message if the self._actual is set to __NIL_VALUE. ]]
function __ParamChecker:notNil()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end
    if self._actual == __NIL_VALUE then error(_format(self, '{$method:}{$name} cannot be nil'), self._errorLevel) end
    return self
end

--[[
    Determines whether the self._actual is a certain type. The expected parameter can be either a string
    representing the type, or a type of string types.
]]
function __ParamChecker:isType(...)
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)
    local expected = {n=select('#', ...), ...}

    for i = expected.n, 1, -1 do
        if not (type(expected[i]) == 'string') then table.remove(expected, i) end
    end

    if #expected == 0 then return self end

    for i = 1, #expected do
        if type_a == expected[i] then return self end

        if type_a == 'userdata' and self._actual.type then
            if self._actual:type() == expected[i] then return self end
            if self._actual:typeOf(expected[i]) then return self end
        end

        if type_a == 'table' and self._actual.type then
            if self._actual:type() == expected[i] then return self end
            if self._actual:typeOf(expected[i]) then return self end
        end
    end

    if type_a == 'userdata' and self._actual.type then type_a = self._actual:type() end
    if type_a == 'table' and self._actual.type then type_a = self._actual:type() end

    local errorStr = '{$method:}{$name} is an invalid type : expected ('.._join(expected, ',')..') : actual ('..type_a..')'
    error(_format(self, errorStr), self._errorLevel)

    return self
end

--[[ Determines if the self._actual is a number. ]]
function __ParamChecker:isNumber()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'number') then
        local errorStr = '{$method:}{$name} is not a number type : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a string. ]]
function __ParamChecker:isString()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'string') then
        local errorStr = '{$method:}{$name} is not a string : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a boolean. ]]
function __ParamChecker:isBoolean()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'boolean') then
        local errorStr = '{$method:}{$name} is not a boolean type : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a table. ]]
function __ParamChecker:isTable()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'table') then
        local errorStr = '{$method:}{$name} is not a table type : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a userdata type. ]]
function __ParamChecker:isUserData()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'userdata') then
        local errorStr = '{$method:}{$name} is not a userdata type : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a function type. ]]
function __ParamChecker:isFunction()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'function') then
        local errorStr = '{$method:}{$name} is not a function : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is a thread type. ]]
function __ParamChecker:isThread()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'thread') then
        local errorStr = '{$method:}{$name} is not a thread : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Determines if the self._actual is nil type. ]]
function __ParamChecker:isNil()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if not (type_a == 'nil') then
        local errorStr = '{$method:}{$name} expected to be a nil : actual ('..type_a..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[
    Determines if the self._actual is a type that can be used to open an image. Note if the self._actual is a
    string or a File/FileData type, this method does not check if the image is valid, just that the file exists
    in the Love2D active directory.
]]
function __ParamChecker:isImage()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if (type_a == 'userdata') and self._actual.type then
        type_a = self._actual:type()
        if (type_a == 'Image') then return self end
        if (type_a == 'ImageData') then return self end
    end

    -- Check if the image file exists.

    local file
    if type_a == 'string' then file = love.filesystem.newFile(self._actual) end
    if type_a == 'FileData' then file = love.filesystem.newFile(self._actual:getFilename()) end
    if type_a == 'File' then file = self._actual end

    local success, message
    if file then
        success, message = file:open('r')
        file:close()
    end
    if success then return self end

    -- One last ditch attempt for FileData. Check the extension is a known image type.
    if type_a == 'FileData' then
        local ext = self._actual:getExtension()
        if _table_contains({'png', 'bmp', 'tga', 'jpg'}, ext) then return self end
    end

    local errorStr = '{$method:}{$name} was determined not to be a valid image' ..
                      (message and (' : (' ..message.. ')') or '')
    error(_format(self, errorStr), self._errorLevel)

    return self
end

--[[
    Determines if the self._actual is a font. Note if the self._actual is a string or a File/FileData type,
    this method does not check if the font is valid, just that the file exists in the Love2D active directory.
]]
function __ParamChecker:isFont()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = (self._actual == __NIL_VALUE) and 'nil' or type(self._actual)

    if (type_a == 'userdata') and self._actual.type then
        type_a = self._actual:type()
        if (type_a == 'Font') then return self end
    end

    -- Check to see if the file exists.

    local file
    if type_a == 'string' then file = love.filesystem.newFile(self._actual) end
    if type_a == 'FileData' then file = love.filesystem.newFile(self._actual:getFilename()) end
    if type_a == 'File' then file = self._actual end

    local success, message
    if file then success, message = file:open('r') end
    if success then return self end

    local errorStr = '{$method:}{$name} was determined not to be a valid font' ..
                      (message and (' : (' ..message.. ')') or '')
    error(_format(self, errorStr), self._errorLevel)

    return self
end

--[[
    Determines whether the self._actual is a table of rgba values. The table can have an optional 'byte' key
    that when set to true will allow the rgba values to have a range of 0 to 255. Otherwise, the rgba values
    must be in the normalized range of 0 to 1. The alpha is an optional value in the table.
]]
function __ParamChecker:isColor()
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local color = self._actual
    local message

    while(true) do
        if not (type(color) == 'table') then
            message = 'must be a color table of rgba values'
            break
        end

        if not next(color) then
            message = 'color table cannot be an empty table'
            break
        end

        if (#color < 3 or #color > 4) then
            message = 'color table must contain a minimum of three rgb color values with a fourth optional alpha value'
            break
        end

        if color.byte and not (type(color.byte) == 'boolean') then
            message = 'color table byte flag must be a boolean'
            break
        end

        local r, g, b, a = unpack(color)
        local type_r, type_g, type_b = type(r), type(g), type(b)
        local type_a = (a and type(a))

        local bottom = 0
        local top = color.byte and 255 or 1
        local _range = function(c) return (c >= bottom and c <= top) end

        if not (type_r == 'number' and type_g == 'number' and type_b == 'number') or (a and not (type_a == 'number')) then
            message = 'color table rgba values must be number values only'
            break
        end

        local validation = (_range(r) and _range(g) and _range(b))
        if a then validation = (validation and _range(a)) end

        if not validation then
            message = 'colors do not fall within the proper range : byte = '..tostring(color.byte==true)..' : {'..
                            tostring(r)..','..tostring(g)..','..tostring(b)..(a and ',' or '')..(a and tostring(a) or '')..'}'
            break
        end

        break -- Prevent infinite loop
    end

    if message then
        local errorStr = '{$method:}{$name} ' .. message
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[
    Determines if the self._actual equals the expected parameter. If the self._actual and expected are both
    tables, this method will do a deep compare of the table contents. Be aware that using large tables with
    this method may cause a stack overflow.
]]
function __ParamChecker:equals(expected)
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a, type_e = type(self._actual), type(expected)

    local isError = false
    if (type_a == 'table') and (type_e == 'table') then
        if not _tables_equal(self._actual, expected) then
            isError = true
        end
    elseif not (type_a == type_e) then
        isError = true
    elseif not (self._actual == expected) then
        isError = true
    end

    if isError then
        local errorStr = '{$method:}{$name} does not equal expected value' ..
                          ((_is_printable_type(type_a) and _is_printable_type(type_e)) and
                          (' : expected ('..tostring(expected)..') : actual ('..tostring(self._actual)..')') or '')
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[
    Determines if the self._actual does not equal the expected parameter. If the self._actual and expected are both
    tables, this method will do a deep compare of the table contents. Be aware that using large tables with
    this method may cause a stack overflow.
]]
function __ParamChecker:notEquals(expected)
    if (self._actual == nil) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a, type_e = type(self._actual), type(expected)

    local isError = false
    if (type_a == 'table') and (type_e == 'table') then
        if _tables_equal(self._actual, expected) then
            isError = true
        end
    elseif (self._actual == expected) then
        isError = true
    end

    if isError then
        local errorStr = '{$method:}{$name} was not expected to equal value'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[
    Determines whether the self._actual matches any of the parameter values.
]]
function __ParamChecker:anyOf(...)
    if (self._actual == nil) or (self._actual == __NIL_VALUE) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local expected = {n=select('#', ...), ...}

    if not _table_contains(expected, self._actual) then
        local errorStr = '{$method:}{$name} does not match any of the expected values'..
                         (_is_printable_type(type(self._actual)) and
                         (' : expected ('.._join(expected, ',')..') : actual ('..tostring(self._actual)..')') or '')
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[
    Checks if self._actual appears at least once in the expected table. If self._actual is a table, then
    each array element is compared with the expected table.
]]
function __ParamChecker:anyOfItems(expected)
    if (self._actual == nil) then return self end
    if not (type(expected) == 'table') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local type_a = type(self._actual)

    local isError = false
    if type_a == 'table' then
        for _, v in ipairs(self._actual) do
            if not _table_contains(expected, v) then isError = true; break end
        end
    else
        if not _table_contains(expected, self._actual) then isError = true end
    end

    if isError then
        local errorStr = '{$method:}{$name} does not match any of the expected items in the expected table'..
                         (_is_printable_type(type(self._actual)) and
                         (' : expected ('.._join(expected, ',')..') : actual ('..tostring(self._actual)..')') or '')
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Checks if the self._actual is an empty table or an empty string. ]]
function __ParamChecker:notEmpty()
    local type_a = type(self._actual)
    if (self._actual == nil) or not ((type_a == 'table') or (type_a == 'string')) then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if type_a == 'table' then
        if not next(self._actual) then
            error(_format(self, '{$method:}{$name} cannot be an empty table'), self._errorLevel)
        end
    elseif type_a == 'string' then
        if self._actual == '' then
            error(_format(self, '{$method:}{$name} cannot be an empty string'), self._errorLevel)
        end
    end

    return self
end

--[[ Checks if the self._actual table has the provided keys in its hash table. ]]
function __ParamChecker:hasKeys(...)
    if (self._actual == nil) or not (type(self._actual) == 'table') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    local expected = {n=select('#', ...), ...}

    for i = 1, expected.n do
        local type_e = type(expected[i])
        if not (type_e == 'string' or type_e == 'number') then goto continue end
        if expected[i] and not self._actual[expected[i]] then
            local errorStr = '{$method:}{$name} missing expected hash key(s) : expected ('.._join(expected, ',')..')'
            error(_format(self, errorStr), self._errorLevel)
        end
        ::continue::
    end

    return self
end

--[[
    Checks if the self._actual falls within a specified range. The self._actual and method parameters must all
    be a number for this method to work.
]]
function __ParamChecker:range(min, max)
    if (self._actual == nil) or not (type(self._actual) == 'number') then return self end
    if not (type(min) == 'number' and type(max) == 'number') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if (self._actual < min) or (self._actual > max) then
        local errorStr = '{$method:}{$name} must fall inside range : range ('..min..','..max..') : actual ('..
                         tostring(self._actual)..')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Checks if the self._actual is a number that is less than the expected parameter. This will only
    work on numbers and does not check the table metatable for the _lt metamethod. ]]
function __ParamChecker:lt(expected)
    if (self._actual == nil) or not (type(self._actual) == 'number') then return self end
    if not (type(expected) == 'number') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if not (self._actual < expected) then
        local errorStr = '{$method:}{$name} must be less than expected value : expected (' .. expected ..
                         ') : actual (' .. self._actual .. ')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Checks if the self._actual is a number that is less than or equal the expected parameter. This will only
    work on numbers and does not check the table metatable for the _lt metamethod. ]]
function __ParamChecker:le(expected)
    if (self._actual == nil) or not (type(self._actual) == 'number') then return self end
    if not (type(expected) == 'number') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if not (self._actual <= expected) then
        local errorStr = '{$method:}{$name} must be less than or equal the expected value : expected (' .. expected ..
                         ') : actual (' .. self._actual .. ')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Checks if the self._actual is a number that is greater than the expected parameter. This will only
    work on numbers and does not check the table metatable for the _lt metamethod. ]]
function __ParamChecker:gt(expected)
    if (self._actual == nil) or not (type(self._actual) == 'number') then return self end
    if not (type(expected) == 'number') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if not (self._actual > expected) then
        local errorStr = '{$method:}{$name} must be greater than the expected value : expected (' .. expected ..
                         ') : actual (' .. self._actual .. ')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end

--[[ Checks if the self._actual is a number that is greater than or equal the expected parameter. This will only
    work on numbers and does not check the table metatable for the _lt metamethod. ]]
function __ParamChecker:ge(expected)
    if (self._actual == nil) or not (type(self._actual) == 'number') then return self end
    if not (type(expected) == 'number') then return self end
    if self._ifNotNil and (self._actual == __NIL_VALUE) then return self end

    if not (self._actual >= expected) then
        local errorStr = '{$method:}{$name} must be greater than or equal to the expected value : expected (' .. expected ..
                         ') : actual (' .. self._actual .. ')'
        error(_format(self, errorStr), self._errorLevel)
    end

    return self
end


--[[
    STATIC METHODS
]]

function _params.enableParameterChecks(enable)
    enable = (enable == true)

    if enable then
        return setmetatable({enableParameterChecks = _params.enableParameterChecks}, {
            __call = function(_, ...) return __ParamChecker(...) end
        })
    else
        local Empty = Class{__name = 'Empty'}

        for name, object in pairs(__ParamChecker) do
            if name == 'type' or name == 'typeOf' or name == 'clone' or name == 'new' or name == 'includes' then
                goto continue
            end

            if type(object) == 'function' then
                Empty[name] = function(self) return self end
            end

            ::continue::
        end

        return setmetatable({enableParameterChecks = _params.enableParameterChecks}, {
            __call=function(_, ...) return Empty(...) end
        })
    end
end

return _params