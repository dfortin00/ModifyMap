
local _array = {}

local function _table_compare(t1, t2, ignore_mt)
    local type1 = type(t1)
    local type2 = type(t2)

    if not (type1 == type2) then return false end

    -- Non-table types can be directly compared
    if not (type1 == 'table') and not (type2 == 'table') then return t1 == t2 end

    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end

    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not _table_compare(v1, v2) then return false end
    end

    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not _table_compare(v1, v2) then return false end
    end

    return true
end

--[[
    Returns the first index in the array that matches the provided value. If the value is not found,
    the method returns nil.

    This method will also do an optional deep comparison of table values, and match them based on their
    contents, and not just their references. Be aware that doing a deep comparison can sometimes cause a
    stack overflow for larger tables.

    This method does not modify the original table.
]]
function _array.indexOf(t, value, fromIndex, deep)
    if not(type(t) == 'table') then error("<utils>.array.indexOf: param #1 must be a table", 2) end
    if fromIndex and not(type(fromIndex) == 'number') then error("<utils>.array.indexOf: param #3 must be a number", 2) end

    if not fromIndex or fromIndex < 1 then fromIndex = 1 end
    if fromIndex > #t then fromIndex = #t end

    for i = fromIndex, #t do
        if deep then
            if _table_compare(t[i], value) then return i end
        else
            if t[i] == value then return i end
        end
    end
end

--[[
    Returns a shallow copy of the array into a new array object selected from start to last.

    The start parameter begins at 1 and counts up to the length of the array. If start is larger than
    the length of the array, then the method will return an empty table. If start is less than 1, then
    the start value becomes a zero-based count from the end of the array (e.g. start = 0 is the same as
    start = #array).

    The last parameter begins at 1 and counts up to the length of the array. If last is larger than the size
    of the array, then last will be modified to equal the length of the array. If last is less than start, then
    last will be set to equal start. The last count will be included in the slice (e.g. start = 1, last = 2 returns
    the first and second elements in the array slice).

    The original table is not modified.
]]
function _array.slice(t, start, last)
    if not(type(t) == 'table') then error("<utils>.array.slice: param #1 must be a table", 2) end
    if start and not(type(start) == 'number') then error("<utils>.array.slice: param #2 must be a number", 2) end
    if last and not(type(last) == 'number') then error("<utils>.array.slice: param #3 must be a number", 2) end

    if not start then start = 1 end
    if not last then last = #t end

    if start < 1 then start = (#t + start) > 0 and (#t + start) or 1 end
    if last < 1 then last = (#t + last) > start and (#t + last) or start end
    if last > #t then last = #t end

    local temp = {}
    for i = start, last do
        temp[#temp + 1] = t[i]
    end

    return temp
end

return _array