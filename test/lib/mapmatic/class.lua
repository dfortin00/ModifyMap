--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local function _include_helper(to, from, seen)
	if from == nil then
		return to
	elseif not (type(from) == 'table') then
		return from
	elseif seen[from] then
		return seen[from]
	end

	seen[from] = to
	for k,v in pairs(from) do
		if (k == "__includes") then
			if (type(to) == "table") and not to.__includes then
				to.__includes = from
			end
		else
			k = _include_helper({}, k, seen) -- keys might also be tables
			if to[k] == nil then
				to[k] = _include_helper({}, v, seen)
			end
		end
	end
	return to
end

-- deeply copies `other' into `class'. keys in `other' that are already
-- defined in `class' are omitted
local function _include(class, other)
	return _include_helper(class, other, {})
end

-- returns a deep copy of `other'
local function _clone(other)
	return setmetatable(_include({}, other), getmetatable(other))
end

local function _type(class)
	return class.__name
end

local function _typeOf(class, objType)
	if not (type(objType) == 'string') then return false end
	if objType == 'Class' then return true end

	if class.__name == objType then return true end
	if class.__includes then
		return _typeOf(class.__includes, objType)
	end

	return false
end

local function _version(class)
	return class.__version
end

local function _new(class)
	-- mixins
	class = class or {}  -- class can be nil
	local inc = class.__includes or {}
	if getmetatable(inc) then inc = {inc} end

	for _, other in ipairs(inc) do
		if type(other) == "string" then
			other = _G[other]
		end
		_include(class, other)
	end

	-- class implementation
	class.__index   = class
	class.__name    = class.__name or 'Class'
	class.__version = class.__version or nil

	class.init    = class.init    or class[1] or function() end
	class.include = class.include or _include
	class.clone   = class.clone   or _clone
	class.type    = _type
	class.typeOf  = _typeOf
	class.version = _version

	-- constructor call
	return setmetatable(class, {__call = function(c, ...)
		local o = setmetatable({}, c)
		o:init(...)
		return o
	end})
end

-- interface for cross class-system compatibility (see https://github.com/bartbes/Class-Commons).
if class_commons ~= false and not common then
	common = {}
	function common.class(name, prototype, parent)
		return _new{__includes = {prototype, parent}}
	end
	function common.instance(class, ...)
		return class(...)
	end
end


-- the module
return setmetatable({new = _new, include = _include, clone = _clone},
	{__call = function(_,...) return _new(...) end})
