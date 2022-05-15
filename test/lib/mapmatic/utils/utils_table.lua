
local _table = {}

--[[ Returns a deep copy of a table. The original table will not be modified. ]]
function _table.copy(t, seen)
    -- Handle non-tables and previously-seen tables.
    if type(t) ~= 'table' then return t end
    if seen and seen[t] then return seen[t] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[t] = res
    for k, v in pairs(t) do res[_table.copy(k, s)] = _table.copy(v, s) end
    return setmetatable(res, getmetatable(t))
end

--[[
    Counts all entries in a table, regardless whether they are an array or a map entry.

    Note the #operator will only work on array entries. The rules for the # operator can be found under
    the comment for the utils.array.count() method.

    The original table will not be modified.
]]
function _table.getn(t)
    if t == nil or not (type(t) == 'table') then return 0 end

    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

--[[ Returns the keys of a table as an array. Note: Order is not guaranteed. The original table is not modified. ]]
function _table.keys(t)
    if not (type(t) == 'table') then return {} end

    local temp = {}
    for k, _ in pairs(t) do
        temp[#temp + 1] = k
    end
    return temp
end

--[[
Recursive table printing function.
For more information: https://docs.coronalabs.com/tutorial/data/outputTable/index.html

The level parameter determines how many levels into the table should be printed.
Note: You can also use pprint() as an alias for this method.
]]
function _table.print(t, level)
    local print_r_cache={}

    local function table_name(t)
        if not (type(t) == 'table') then return t end
        local tableName = tostring(t)
        if t.__name then tableName = tableName:gsub('table', t.__name) end
        return tableName
    end

    local function sub_print_r(t, indent, subLevel)
        if level and (subLevel >= level) then return end

        if (print_r_cache[table_name(t)]) then
            print(indent .. "*" .. table_name(t))
        else
            print_r_cache[table_name(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. table_name(val) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8), subLevel + 1)
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(table_name(t)))
            end
        end
    end

    if t == nil then
        print("nil")
    elseif (type(t) == "table") then
        print(table_name(t) .. " {")
        sub_print_r(t, "  ", 0)
        print("}")
    else
        sub_print_r(t, "", 0)
    end
    print()
end

--[[ Returns the values of a table as an array. Note: Order is not guaranteed. The original table is not modified. ]]
function _table.values(t)
    if not (type(t) == 'table') then return {} end

    local temp = {}
    for _, v in pairs(t) do
        temp[#temp + 1] = v
    end
    return temp
end


return _table